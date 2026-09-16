# This app is a raft. — 이 앱도 뗏목이다.
#
# 언어 — 늘리지 않고 준비만. 지금은 한국어와 영어 둘이고, 셋째 언어는 문장이
# 굳은 뒤에 그 언어로 쓰는 사람이 쓴다. 기계 번역은 없다.
#
# 이 파일이 지키는 것: 셋째 언어가 올 때 손댈 곳이 정해져 있고, 그 밖의
# 어디에도 언어가 박혀 있지 않다는 것.
require "test_helper"
require_relative "../test_helpers/copy_locks"

class LanguagesTest < ActionDispatch::IntegrationTest
  LOCALES = I18n.available_locales.map(&:to_s)

  setup do
    heart_sutra
    nine_abidings
  end

  # 화면에 나가는 글은 로케일 파일에만 있다. 뷰에 글자를 직접 적으면 깨진다.
  test "화면의 글은 로케일 파일 밖에 없다" do
    strays = []

    Rails.root.glob("app/views/**/*.erb").each do |file|
      next if file.to_s.include?("/pwa/") || file.to_s.include?("/layouts/mailer")

      body = file.read.gsub(/<%#.*?%>/m, "").gsub(/<%.*?%>/m, "\u{E000}").gsub(/<!--.*?-->/m, "")

      # 속성 안의 글 — 사람이 읽는 속성만 본다. data-* 와 값은 손잡이지 글이 아니다.
      body.scan(/\b(alt|aria-label|title|placeholder)="([^"]*)"/).each do |attr, value|
        strays << "#{file.basename}: #{attr}=\"#{value}\"" if value =~ /[가-힣A-Za-z]/ && !value.include?("\u{E000}")
      end

      # 태그 밖의 글. 속성값 안의 > (data-action 의 ->) 에 속지 않는다.
      body.gsub(/<(?:[^>"']|"[^"]*"|'[^']*')*>/, " ").split("\u{E000}").each do |chunk|
        text = chunk.gsub(/&[a-z]+;|&#\d+;/, " ").strip
        strays << "#{file.basename}: #{text[0, 50].inspect}" if text =~ /[가-힣A-Za-z]/
      end
    end

    assert_empty strays, "로케일 밖에 글이 있다"
  end

  # 언어의 목록은 config/application.rb 한 곳에서 온다.
  test "언어의 목록은 한 곳에만 있다" do
    assert_equal LOCALES, User::LOCALES
    assert_match(/Regexp\.union\(I18n\.available_locales/, Rails.root.join("config/routes.rb").read, "경로에 언어가 박혀 있다")
    assert_no_match(/%w\[ko en\]|%i\[ko en\]|\/ko\|en\//, Rails.root.glob("app/**/*.rb").map(&:read).join, "앱 코드에 언어 목록이 박혀 있다")

    LOCALES.each { |locale| assert I18n.exists?("app.name", locale), "#{locale} 로케일 파일이 없다" }
  end

  # 셋째 언어의 로케일 파일은 한국어의 모든 열쇠를 가져야 한다. 빠진 열쇠는
  # fallback 으로 영어가 슬쩍 나오므로, 여기서 잡지 않으면 아무도 모른다.
  # 레일스 자체의 열쇠(날짜 · 오류 · 숫자 형식)는 앱의 말이 아니라 여기서 빼고 본다.
  FRAMEWORK = %w[date time datetime number errors support helpers activerecord activemodel].freeze

  test "로케일 파일은 서로 같은 열쇠를 가진다" do
    keys = LOCALES.to_h do |locale|
      [ locale, leaf_keys(I18n.t(".", locale: locale, default: {}).except(*FRAMEWORK.map(&:to_sym))).to_set ]
    end
    base = keys.fetch("ko")

    LOCALES.each do |locale|
      missing = base - keys.fetch(locale)
      extra = keys.fetch(locale) - base

      assert_empty missing.to_a.sort, "#{locale} 에 빠진 열쇠"
      assert_empty extra.to_a.sort, "#{locale} 에만 있는 열쇠"
    end
  end

  # 금지어는 언어별로 나뉜다. 언어가 하나 늘면 그 언어의 목록 전부가 있어야 한다.
  test "금지어 목록은 언어마다 빠짐없이 있다" do
    LOCALES.each do |locale|
      words = CopyLocks::WORDS[locale]

      assert words, "#{locale} 의 금지어 목록이 없다"
      assert_equal CopyLocks::CATEGORIES, words.keys, "#{locale} 의 금지어 목록에 빠진 항목이 있다"
      words.each_value { |pattern| assert_kind_of Regexp, pattern }
    end
  end

  # 데이터의 언어별 칸은 Localized 한 곳의 규칙을 따른다. 모델이나 뷰가 따로
  # 언어를 가르면 셋째 언어에서 그 자리만 어긋난다.
  test "언어를 가르는 곳은 Localized 하나뿐이다" do
    allowed = %w[app/models/concerns/localized.rb app/views/layouts/application.html.erb
                 app/controllers/concerns/localization.rb app/controllers/users_controller.rb
                 app/controllers/concerns/authentication.rb app/models/abiding.rb]
    branching = Rails.root.glob("app/**/*.{rb,erb}").select { |f| f.read.match?(/I18n\.locale\s*(==|!=)|locale == :|I18n\.locale\.to_s ==/) }

    assert_empty branching.map { |f| f.relative_path_from(Rails.root).to_s } - allowed, "언어를 따로 가르는 곳이 있다"
  end

  test "없는 언어의 칸은 영어로 보이고, 한국어에만 뜻이 있는 칸은 비운다" do
    abiding = nine_abidings.first
    char = heart_sutra.chars.first

    I18n.with_locale(:en) do
      assert_equal abiding.one_line_en, abiding.one_line_here
      assert_nil char.reading_here, "훈음이 영어 화면에 나간다"
      assert_equal char.gloss_en, char.sense_here_here
    end

    I18n.with_locale(:ko) do
      assert_equal abiding.one_line, abiding.one_line_here
      assert_equal char.reading, char.reading_here
    end

    # 셋째 언어가 와도 칸이 없으면 영어로 — 실제 언어를 더하지 않고 규칙만 본다.
    stranger = Class.new do
      include Localized
      localized :one_line
      def one_line = "한"
      def one_line_en = "one"
    end.new
    I18n.available_locales.tap do |was|
      I18n.available_locales = was + [ :xx ]
      I18n.with_locale(:xx) { assert_equal "one", stranger.one_line_here }
    ensure
      I18n.available_locales = was
    end
  end

  # 설정의 언어 고르기와 화면 아래의 전환이 모든 화면에 닿는다 —
  # 몰입 화면(앉는 중 · 무위 · 문 셋 · 몫이 끝난 자리)만 빼고.
  test "언어 전환이 몰입 화면 밖의 모든 화면에 있다" do
    user = users(:one)
    sign_in_as user

    open = [ today_path, days_path, new_sitting_path, new_copying_path, pagoda_path, settings_path,
             guide_path, guide_chapter_path("abidings"), abiding_path(nine_abidings.first), new_rest_path,
             day_path(user.today) ]
    open.each do |page|
      get page
      assert_response :success, "#{page} 가 열리지 않는다"
      assert_select ".locales", count: 1, message: "#{page} 에 언어 전환이 없다"
      assert_select ".locales a", count: LOCALES.size - 1, message: "#{page} 의 전환이 언어 수와 다르다"
    end

    get settings_path
    LOCALES.each { |locale| assert_select "input[name='user[locale]'][value=?]", locale }

    user.update!(onboarded_at: nil)
    [ threshold_path, threshold_naming_path, threshold_breath_path ].each do |door|
      get door
      assert_select ".locales", false, "#{door} 에 언어 전환이 있다"
    end
    user.update!(onboarded_at: Time.current)

    post sittings_path, params: { sitting: { length: "tea" } }
    follow_redirect!
    assert_select ".locales", false, "앉는 중에 언어 전환이 있다"
  end

  private
    def leaf_keys(hash, prefix = nil)
      hash.flat_map do |key, value|
        name = [ prefix, key ].compact.join(".")
        value.is_a?(Hash) ? leaf_keys(value, name) : [ name ]
      end
    end
end

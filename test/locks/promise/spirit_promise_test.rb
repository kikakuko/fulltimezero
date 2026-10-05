# This app is a raft. — 이 앱도 뗏목이다.
#
# SPIRIT 의 약속을 화면에서 검증한다 — 사용자가 배신당했다고 느낄 수 있는 것들.
# 바깥을 부르지 않는다. 알림이 새지 않는다. 사람을 재지 않는다(퍼센트 · 연속 · 분 · 층 ·
# 남은 것). 가르치지 않는다. 인용에는 출처가 있다.
# 「숫자가 보이느냐」는 결 쪽이다 — test/locks/form/spirit_form_test.rb.
require "test_helper"
require_relative "../../test_helpers/copy_locks"

class SpiritPromiseTest < ActionDispatch::IntegrationTest
  include Screens

  setup { heart_sutra }

  # 사람을 재지 않는다 — 퍼센트도, 연속도, 분도. 숫자가 보이느냐는 「결」 쪽에서 따로 본다.
  test "어느 화면에도 사람을 재는 것이 없다 — 퍼센트 · 연속 · 분" do
    each_page do |page, locale|
      text = visible_text

      assert_no_match(/%/, text, "#{page}(#{locale}) 화면에 퍼센트가 보인다")
      assert_no_match(/일째|days?\b.*streak|streak/i, text, "#{page}(#{locale}) 화면에 연속기록이 보인다")
      assert_no_match(/\d\s*(분|minutes?|mins?)\b/i, text, "#{page}(#{locale}) 화면에 분이 보인다")
    end
  end

  # 몰입 화면도 재지 않고 바깥을 부르지 않는다. 기록이 있어야 열리므로 따로 연다.
  test "앉는 중에도 무위에도 재는 것이 없고, 바깥을 부르지 않는다" do
    sign_in_as users(:one)

    I18n.available_locales.each do |locale|
      post sittings_path(locale: locale), params: { sitting: { length: "incense", bell: "1" } }
      follow_redirect!
      assert_unmeasured_screen "앉는 중", locale

      post nothing_path(locale: locale), params: { bell: "1" }
      follow_redirect!
      assert_unmeasured_screen "무위", locale
    end
  end

  # 남은 시간을 스크린리더에게만 숫자로 알려주지 않는다.
  # 보이는 사람도 모르는 것을 들리는 사람에게만 알려주는 것은 형평이 아니다.
  test "앉는 중 화면은 스크린리더에게도 남은 시간을 말하지 않는다" do
    sign_in_as users(:one)
    post sittings_path, params: { sitting: { length: "long" } }
    follow_redirect!

    labels = Nokogiri::HTML(response.body).css("[aria-label], title").map(&:text).join(" ")

    assert_no_match(/\d/, labels, "접근성 텍스트에 숫자가 있다")
    assert_no_match(/분|minutes?|remaining|남은/i, labels)
  end
  # 이 앱은 쉼을 가르치지 않는다 — 쉬는 마음이 형상을 얻게 할 뿐이다(§5).
  # 인용 원문은 예외다. 옛글의 낱말은 옛글의 것이다.
  test "카피가 쉼을 가르치지 않는다 — 수행·훈련·단계의 말이 없다" do
    I18n.available_locales.map(&:to_s).each do |locale|
      copy = YAML.load_file(Rails.root.join("config/locales/#{locale}.yml")).fetch(locale)

      flatten_copy(copy).reject { |line| line.start_with?("「") }.each do |line|
        assert_no_match CopyLocks.pattern(:teaching, locale), line, "#{locale} 카피가 가르친다: #{line[0, 60]}"
      end
    end
  end
  # 화면이 스스로 바깥을 부르지 않는다.
  #
  # 링크 하나는 요청이 아니다 — 사용자가 눌러야만 열리는 문이다.
  # 그러나 자동으로 실려 오는 것(그림·글꼴·스크립트)과 미리 이어 두는
  # 것(preconnect·prefetch·preload)은 사용자가 부르지 않았는데도
  # 나가는 요청이므로 하나도 둘 수 없다.
  test "어느 화면도 제3자에게 요청을 보내지 않는다" do
    each_page { |page, locale| assert_no_outward_requests(page, locale) }
  end
  test "바깥으로 나가는 문은 눌러야만 열린다" do
    outward = false

    I18n.available_locales.each do |locale|
      GuideController::CHAPTERS.each do |chapter|
        get guide_chapter_path(chapter, locale: locale)
        assert_no_outward_requests("guide/#{chapter}", locale)

        Nokogiri::HTML(response.body).css("a[href^='http']").each do |door|
          outward = true
          assert_equal "_blank", door["target"], "바깥 문이 이 창을 덮어쓴다: #{door["href"]}"
          assert_includes door["rel"].to_s, "noopener", "바깥 문에 noopener 가 없다"
          assert_equal "false", door["data-turbo"], "터보가 바깥 문을 미리 당겨 온다"
        end
      end
    end

    assert outward, "출전이 원문으로 이어지지 않는다"
  end
  test "쉼을 기록해도 알림은 한 통도 나가지 않는다" do
    sign_in_as users(:one)

    assert_no_enqueued_emails do
      post rests_path(locale: :ko), params: { rest: { duration: "a_while" } }
      get today_path(locale: :ko)
      get moon_path(locale: :ko)
    end
  end
  # 탑은 언제든 볼 수 있다. 세는 것을 막는 일은 화면이 한다 — 층도, 남은 것도, 쓰지 않은
  # 칸의 자리도 화면으로 나가지 않는다. 숫자가 보이느냐는 「결」 쪽에서 본다.
  test "탑은 세지 않는다 — 층도 남은 것도 쓰지 않은 칸도 없다" do
    user = users(:one)
    rows = heart_sutra.chars.where(pos: 1..3).map do |char|
      { user_id: user.id, sutra_char_id: char.id, copied_on: user.today - (4 - char.pos),
        glyph_paths: [ [ [ 0.5, 0.5 ] ] ], created_at: Time.current, updated_at: Time.current }
    end
    Copying.insert_all!(rows)
    sign_in_as user

    I18n.available_locales.each do |locale|
      get pagoda_path(locale: locale)

      assert_no_match(/층|floor|layer|남은|남았|left|remaining/i, visible_text, "탑 화면이 층을 세거나 남은 것을 말한다")
    end

    scene = JSON.parse(css_select("[data-pagoda-scene-value]").first["data-pagoda-scene-value"])
    assert_equal 3, scene["cells"].size, "쓰지 않은 칸의 자리가 화면으로 나갔다"
    assert scene["cells"].none? { |cell| cell["fresh"] }, "보는 자리에 방금 올린 자가 있다"
  end

  # 「쉼의 안내」에 인용문이 들어온다면 그 출처는 CC0 원문뿐이어야 한다.
  test "쉼의 안내에는 출처 없는 인용문이 없다" do
    sources = File.read(Rails.root.join("docs/SOURCES.md"))
    assert_match(/CC0/, sources, "출처 문서에 라이선스 원칙이 없다")

    copy = I18n.available_locales.flat_map { |l| flatten_copy(I18n.t("guide", locale: l)) }.join(" ")
    quotations = copy.scan(/[“「『]([^”」』]+)[”」』]/).flatten

    # 출처 문서에서는 긴 인용문이 여러 줄로 접혀 있다. 줄바꿈이 출처
    # 확인을 무력화해서는 안 되므로 양쪽의 공백을 고르고 견준다.
    haystack = flatten_spaces(sources.gsub(/^\s*>\s?/, ""))

    quotations.each do |quotation|
      assert_includes haystack, flatten_spaces(quotation),
        "인용문 #{quotation.inspect} 의 출처가 docs/SOURCES.md 에 없다"
    end
  end

  private
    # 재지 않는 화면 — 분도 없고 바깥도 부르지 않는다.
    def assert_unmeasured_screen(name, locale)
      assert_response :success, "#{name}(#{locale}) 이 열리지 않는다"
      assert_no_match(/\d\s*(분|minutes?|mins?)\b/i, visible_text, "#{name}(#{locale}) 화면에 분이 보인다")

      hosts = response.body.scan(%r{https?://([^/"'\s>]+)}).flatten.uniq
      assert_empty hosts, "#{name}(#{locale}) 화면이 바깥을 부른다: #{hosts.inspect}"
    end
end

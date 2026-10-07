# This app is a raft. — 이 앱도 뗏목이다.
#
# 인용의 약속 — 지은 말에 경의 이름을 붙이지 않는다. 인용 부품(.verse)에는 반드시 출전이
# 붙는다. 이건 말투가 아니라 출처에 대한 정직이다. 우리가 쓴 문장 밑에 경의 이름이 붙으면
# 앱이 거짓말을 하는 것이다. 황토로 쓰느냐 먹으로 쓰느냐는 결 쪽이다 —
# test/locks/form/verse_form_test.rb.
require "test_helper"

class VersePromiseTest < ActionDispatch::IntegrationTest
  setup do
    heart_sutra
    nine_abidings
    sign_in_as users(:one)
  end

  # 인용이 서는 화면들. 새 화면에 인용을 세우면 여기에 더한다.
  PAGES = %i[threshold_path].freeze
  SCRIPTURE = /\A『[^』]+』/

  test "인용이 서는 곳마다 바로 곁에 출전이 선다" do
    I18n.available_locales.each do |locale|
      PAGES.each do |page|
        get send(page, locale: locale)
        verses = css_select(".verse")
        assert_not_empty verses, "#{page} 에 인용이 없다 — 목록에서 빼야 한다"

        verses.each do |verse|
          source = verse.next_element
          assert source && source["class"].to_s.match?(/source/), "#{page} 의 인용 곁에 출전이 없다: #{verse.text.strip}"
        end
      end
    end
  end

  test "인용 부품의 출전은 경이다 — 서버가 세우는 인용" do
    get threshold_path(locale: :ko)
    css_select(".verse").each do |verse|
      assert_match SCRIPTURE, verse.next_element.text.strip, "경이 아닌 한 줄에 황토가 붙었다: #{verse.text.strip}"
    end
  end

  test "전각 카드는 경의 말에만 인용 부품을 붙인다 — 미륵당과 예경당의 한 줄은 먹이다" do
    js = Rails.root.join("app/javascript/controllers/compound_controller.js").read
    ko = js[/ko: \{(.*?)\}/m, 1]
    get today_path(locale: :ko)
    doc = Nokogiri::HTML(response.body)

    assert_select ".compound__card-verse.verse", false, "카드의 한 줄이 처음부터 황토다"
    assert_match(/classList\.toggle\("verse", scripture === true\)/, js)
    Compound::CARD_HALLS.each do |hall|
      anchor = doc.at_css("a.compound__hall--#{hall.key}")
      source = anchor["data-compound-source-param"].presence || ko[/\b#{hall.key}: "([^"]+)"/, 1]

      assert_equal hall.scripture.to_s, anchor["data-compound-scripture-param"]
      if hall.scripture
        assert_match SCRIPTURE, source, "#{hall.key} 는 경의 말이라면서 출전이 경이 아니다"
      else
        assert_no_match SCRIPTURE, source.to_s, "#{hall.key} 의 출전이 경인데 먹으로 섰다"
      end
    end
    # 먹으로 서는 둘 — 미륵당의 한 줄은 우리가 지은 말이고 출전은 장소다.
    # 예경당의 한 줄은 보현행원품의 뜻을 우리 말로 옮긴 것이라 출전을 달지 않는다.
    # 역경원 번역본의 문장을 대조해 올리면 그때 경구가 된다(Citation).
    assert_equal [ :maitreya, :bowing ].sort, Compound::CARD_HALLS.reject(&:scripture).map(&:key).sort
  end

  test "문의 경 한 줄은 출전과 함께 선다" do
    I18n.available_locales.each do |locale|
      get threshold_path(locale: locale)

      assert_select "figure .verse", text: I18n.t("threshold.stop.quote", locale: locale)
      assert_select "figure .verse + figcaption[class*=source] cite", text: I18n.t("threshold.stop.source", locale: locale)
    end
  end

  # 전각 카드의 인용은 눌러야 채워진다. 채워질 출전이 전각마다 있어야 한다 — 서버가
  # 싣거나(숫자가 없는 것), 스크립트의 출전 상수에 있거나.
  test "전각 카드의 인용마다 채워질 출전이 있다" do
    js = Rails.root.join("app/javascript/controllers/compound_controller.js").read
    get today_path
    doc = Nokogiri::HTML(response.body)

    # 출전은 경의 말에만 붙는다. 우리 말에는 출전이 없다 — 없는 것이 바른 모양이다.
    Compound::CARD_HALLS.select(&:scripture).each do |hall|
      anchor = doc.at_css("a.compound__hall--#{hall.key}")
      next if anchor["data-compound-source-param"].present?

      %w[ko en].each do |locale|
        block = js[/#{locale}: \{(.*?)\}/m, 1].to_s
        assert_match(/\b#{hall.key}: "[^"]+"/, block, "#{hall.key} 카드의 인용에 #{locale} 출전이 없다")
      end
    end
    assert_match(/this\.cardSourceTarget\.textContent = cited/, js, "출전이 카드에 채워지지 않는다")
  end

  test "인용은 적어 둔 화면에만 선다" do
    views = Rails.root.glob("app/views/**/*.erb").select { |file| file.read.match?(/class="(?:[^"]*\s)?verse[\s"]/) }
    places = views.map { |file| file.relative_path_from(Rails.root).to_s }.sort

    assert_equal %w[app/views/onboarding/stop.html.erb], places,
      "인용이 새 화면에 섰다 — PAGES 에 더하고 출전을 곁에 세운다"
  end
end

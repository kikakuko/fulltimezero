# This app is a raft. — 이 앱도 뗏목이다.
#
# 「쉼의 안내」는 카피가 아니라 산문이다. 그래서 두 문장 규정은 걸리지
# 않지만, 어조 규정은 더 엄하게 건다 — 진단하지 않고, 시키지 않고,
# 초대로 끝맺는다. 다섯째 장은 앱 밖을 가리키며 끝난다(제7조).
require "test_helper"
require_relative "../test_helpers/copy_locks"

class GuideTest < ActionDispatch::IntegrationTest
  CHAPTERS = GuideController::CHAPTERS

  # 금지어는 언어별로 CopyLocks 한 곳에 있다.
  DIAGNOSING = CopyLocks.pattern(:diagnosing)
  GRADING = CopyLocks.pattern(:grading)
  COMMANDING = CopyLocks.pattern(:commanding)

  test "다섯 장이 ko/en 양쪽에서 열린다" do
    I18n.available_locales.each do |locale|
      get guide_path(locale: locale)
      assert_response :success

      CHAPTERS.each do |chapter|
        get guide_chapter_path(chapter, locale: locale)
        assert_response :success, "#{chapter}(#{locale}) 가 열리지 않는다"
        assert_operator prose.length, :>, 300, "#{chapter}(#{locale}) 의 본문이 비어 있다"
      end
    end
  end

  test "어느 장도 읽는 이를 진단하지 않는다" do
    each_chapter do |chapter, locale, text|
      assert_no_match DIAGNOSING, text, "#{chapter}(#{locale}) 이 읽는 이를 진단한다"
      assert_no_match GRADING, text, "#{chapter}(#{locale}) 에 등급표의 말이 있다"
    end
  end

  test "어느 장도 시키지 않는다" do
    each_chapter do |chapter, locale, text|
      assert_no_match COMMANDING, text, "#{chapter}(#{locale}) 이 시킨다"
    end
  end

  test "각 장의 끝은 초대다" do
    each_chapter do |chapter, locale, _text|
      ending = Nokogiri::HTML(response.body).css(".guide p").last.text

      assert_no_match COMMANDING, ending, "#{chapter}(#{locale}) 이 명령으로 끝난다"
      assert_no_match(/\]\(|href=/, ending, "#{chapter}(#{locale}) 이 고리로 끝난다")
    end
  end

  # 「」 안의 문장은 인용이고, 인용에는 출전이 따라붙는다.
  test "모든 인용에 출전 줄이 붙어 있다" do
    each_chapter do |chapter, locale, _text|
      page = Nokogiri::HTML(response.body)
      quotes = page.css(".guide blockquote")

      quotes.each do |quote|
        assert quote.css(".source").any?,
          "#{chapter}(#{locale}) 의 인용에 출전이 없다: #{quote.text[0, 40]}"
      end

      assert_operator quotes.size, :<=, 2,
        "#{chapter}(#{locale}) 의 인용이 둘을 넘는다. 이것은 인용집이 아니다."
    end
  end

  test "다섯째 장은 기능으로 회수되지 않고 앱 밖을 가리킨다" do
    I18n.available_locales.each do |locale|
      get guide_chapter_path("complete_rest", locale: locale)

      assert_select ".guide .aside", false, "온전한 쉼 장이 기능으로 이어진다"
      assert_match(/뗏목|raft/i, prose, "앱 밖을 가리키며 끝나지 않는다")
    end
  end

  test "장 끝에 다음 장으로 미는 고리가 없다" do
    CHAPTERS.each do |chapter|
      get guide_chapter_path(chapter)

      links = Nokogiri::HTML(response.body).css(".sheet a").map { |a| a["href"] }

      # 같은 장의 다른 언어 판은 미는 고리가 아니라 언어 전환이다.
      onward = links.grep(%r{/guide/}).reject { |href| href.end_with?("/guide/#{chapter}") }

      assert_empty onward, "#{chapter} 이 다음 장으로 민다"
    end
  end

  # 사경은 이제 자리 넷 가운데 하나다. 안내에도 길이 남아 있다 —
  # 안내를 읽다가 그리로 갈 수 있어야 한다.
  test "사경으로 가는 길은 안내에도 있다" do
    get guide_path
    assert_select "a[href=?]", new_copying_path

    sign_in_as users(:one)
    get today_path
    assert_select "nav.doors a[href=?]", new_copying_path, count: 1
  end

  # 「쉼의 안내」는 문이 아니라 오늘 화면 안의 길이다.
  test "쉼의 안내로 가는 길은 오늘 화면에 있고, 아래 자리에는 없다" do
    sign_in_as users(:one)
    get today_path

    assert_select "main a[href=?]", guide_path, count: 1
    assert_select "nav.doors a[href=?]", guide_path, false
  end

  test "안내에도 숫자와 느낌표와 이모지가 없다" do
    each_chapter do |chapter, locale, text|
      assert_no_match(/\d/, text, "#{chapter}(#{locale}) 에 숫자가 있다")
      assert_no_match(/!/, text, "#{chapter}(#{locale}) 에 느낌표가 있다")
      assert_no_match(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/, text, "#{chapter}(#{locale}) 에 이모지가 있다")
    end
  end

  private
    def prose = Nokogiri::HTML(response.body).css("body").text.gsub(/\s+/, " ")

    def each_chapter
      I18n.available_locales.each do |locale|
        CHAPTERS.each do |chapter|
          get guide_chapter_path(chapter, locale: locale)
          assert_response :success
          yield chapter, locale, prose
        end
      end
    end
end

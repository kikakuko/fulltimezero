# This app is a raft. — 이 앱도 뗏목이다.
#
# 이 앱에 대하여 — 계정 없이 열리고, 마당의 미리보기가 그림이 아니라 마당의 조각 그대로 선다.
# 씨앗의 값(보름 전 사흘)으로 서버에서 그리고, 스크립트를 붙이지 않는다.
require "test_helper"

class AboutFlowTest < ActionDispatch::IntegrationTest
  include Screens

  test "계정 없이 열리고, 미리보기는 마당의 조각 그대로다 — 그림도 스크립트도 누를 곳도 없다" do
    I18n.available_locales.each do |locale|
      get about_path(locale: locale)
      assert_response :success

      frame = css_select(".about-preview .about-preview__frame[inert]").first
      assert frame, "#{locale}: 미리보기 틀이 없다"
      preview = Nokogiri::HTML(frame.to_html)

      assert_equal 1, preview.css("svg.moon").size, "#{locale}: 달이 없다"
      assert_equal 1, preview.css(".seal.rested").size, "#{locale}: 낙관이 없다"
      assert_empty preview.css("img, picture"), "#{locale}: 미리보기에 그림이 들어왔다"
      assert_empty preview.css("[data-controller], [data-action]"), "#{locale}: 미리보기에 스크립트가 붙었다"
      assert_empty preview.css("form, button, a"), "#{locale}: 미리보기에 누를 곳이 있다"
    end
  end

  test "달은 씨앗의 값으로 그린다 — 보름 전 사흘, 정적이다" do
    get about_path

    moon = css_select(".about-preview svg.moon").first
    assert_equal MoonHelper.instance_method(:moon_reading).bind_call(ApplicationController.new.view_context, Rational(25, 28)), moon["aria-label"]
    assert_not_includes moon["class"], "moon--filling", "미리보기의 달이 움직인다"
  end

  # 없는 것들 — 미리보기 바로 아래, 「쓰인 것들」 한 줄 위. 자물쇠의 경로는 화면에 내지 않는다.
  test "없는 것들이 미리보기 아래, 「쓰인 것들」 위에 서고, 자물쇠 경로는 화면에 없다" do
    I18n.available_locales.each do |locale|
      get about_path(locale: locale)
      body = response.body

      lines = I18n.t("about.none.lines", locale: locale)
      assert_select ".about-none h2", text: I18n.t("about.none.title", locale: locale)
      assert_select ".about-none li", count: lines.size
      assert_operator body.index("about-preview"), :<, body.index("about-none"), "#{locale}: 없는 것들이 미리보기 위에 있다"
      assert_operator body.index("about-none"), :<, body.index(credits_path(locale: locale)), "#{locale}: 「쓰인 것들」이 없는 것들 위에 있다"
      assert_no_match(%r{test/locks|_test\.rb}, visible_text, "#{locale}: 자물쇠 경로가 화면에 나왔다")
    end
  end
end

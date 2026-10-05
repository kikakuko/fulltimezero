# This app is a raft. — 이 앱도 뗏목이다.
#
# 아홉 자리의 결 — 발자국 하나 안의 돌 아홉, 자리와 색.
require "test_helper"

class AbidingsFormTest < ActionDispatch::IntegrationTest
  include Screens
  setup do
    @abidings = nine_abidings
    @user = users(:one)
  end


  test "여섯째 장 — 코끼리 발자국 하나 안에 돌 아홉, 번호는 없다" do
    I18n.available_locales.each do |locale|
      get guide_chapter_path("abidings", locale: locale)

      assert_response :success
      assert_select ".footprint svg.footprint__art path.footprint__stone", count: 9
      assert_select ".footprint svg.footprint__art path.footprint__toe", count: 4
      assert_select ".footprint a.stone", count: 9
      @abidings.each do |abiding|
        assert_select ".footprint a.stone[href=?] .stone__name", abiding_path(abiding, locale: locale),
          text: (locale == :en ? abiding.gloss_en : abiding.ko)
      end
      assert_no_match(/\d/, visible_text, "#{locale} 여섯째 장에 숫자가 있다")
      assert_match Abiding.epigraph(locale)[0, 20], visible_text
      assert_match I18n.t("abidings.footprint.line", locale: locale), visible_text
      assert_match I18n.t("abidings.footprint.source", locale: locale), visible_text
      assert_match I18n.t("abidings.thangka", locale: locale), visible_text
    end
  end

  test "돌은 자리마다 발자국 안의 다른 곳에 놓인다 — 자리는 상수에서" do
    get guide_chapter_path("abidings")

    styles = css_select(".footprint a.stone").map { |stone| stone["style"] }
    assert_equal 9, styles.uniq.size
    @abidings.each do |abiding|
      x, y = abiding.footprint
      assert_select ".footprint a.stone[href=?][style=?]", abiding_path(abiding),
        "left:#{((x - 30) / 3.3).round(2)}%; top:#{((y - 110) / 3.8).round(2)}%"
    end
  end

  test "발자국의 색은 :root 에서 온다 — 그림 파일의 색을 쓰지 않는다" do
    partial = Rails.root.join("app/views/abidings/_footprint.html.erb").read
    assert_no_match(/#\h{3,8}\b|fill="|stroke="/, partial, "발자국 그림에 색이 박혀 있다")

    css = Rails.root.join("app/assets/tailwind/application.css").read
    %w[footprint__sole footprint__toe footprint__stone footprint__shadow].each do |part|
      assert_match(/\.#{part} \{[^}]*var\(--(?:paper|paper-deep|ink)\)/, css)
    end
  end
end

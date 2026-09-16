# This app is a raft. — 이 앱도 뗏목이다.
#
# 코끼리의 길 — 앉기의 자리 맨 위. 흔적이지 경지가 아니다.
require "test_helper"

class ElephantFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @abidings = nine_abidings
    sign_in_as @user
  end

  test "앉기 맨 위에 코끼리의 길이 있고, 정거장 아홉은 이름뿐이다" do
    get new_sitting_path

    assert_select ".elephant-field [data-controller=elephant]", count: 0
    assert_select ".elephant-field[data-controller=elephant]", count: 1
    assert_select ".elephant-field__station", count: 9
    @abidings.each { |abiding| assert_select ".elephant-field__station", text: abiding.ko }
    assert_select ".elephant img.elephant__whole[src*=elephant]", count: 1

    # 맨 위 — 앉는다 · 아무것도 하지 않는다보다 앞에 선다.
    main = Nokogiri::HTML(response.body).css("main").to_html
    assert_operator main.index("elephant-field"), :<, main.index("<form"), "코끼리의 길이 맨 위가 아니다"
    assert_no_match(/\d/, visible_text.sub(/한국어.*/, ""), "코끼리의 길에 숫자가 있다")
  end

  test "길은 그리지 않는다 — 숨긴 path 하나뿐이다" do
    get new_sitting_path

    assert_select ".elephant-field__path[d='']", count: 1
    css = Rails.root.join("app/assets/tailwind/application.css").read
    assert_match(/\.elephant-field__path \{ fill: none; stroke: none; \}/, css)
  end

  # 주어는 코끼리다. 정거장은 지명이지 사용자의 경지가 아니다.
  test "카드의 주어는 코끼리고, 읽는 이를 부르지 않는다" do
    %i[ko en].each do |locale|
      get new_sitting_path(locale: locale)

      card = I18n.t("sittings.elephant.card", station: "x", locale: locale)
      assert_match(/\A(코끼리가|The elephant)/, card)
      assert_no_match(/당신|너의|\byou\b|\byour\b/i, card, "#{locale} 카드가 읽는 이를 부른다")
      station = I18n.with_locale(locale) { @abidings.first.name }
      assert_match I18n.t("sittings.elephant.card", station: station, locale: locale), visible_text
    end
  end

  test "흰빛은 그림의 밝기로만 보이고, 양 끝은 상수다" do
    css = Rails.root.join("app/assets/tailwind/application.css").read

    assert_match(/--elephant-dark: 0\.35;/, css)
    assert_match(/--elephant-light: 2\.4;/, css)
    assert_match(/--elephant-width: 104px;/, css)
    assert_match(/filter: grayscale\(1\) brightness\(calc\(var\(--elephant-dark\)/, css)
  end

  test "앵커는 그리는 쪽과 재는 쪽이 같다" do
    js = Rails.root.join("app/javascript/controllers/elephant_controller.js").read
    anchors = js[/export const ANCHORS = \[(.*?)\n\]/m, 1].scan(/\[ (\d+), (\d+) \]/).map { |x, y| [ x.to_i, y.to_i ] }

    assert_equal Elephant::ANCHORS, anchors
    assert_match(/getPointAtLength/, js, "길 위의 점을 재지 않는다")
  end

  test "걸음은 여덟 할 초를 오가고, 움직임을 줄이면 멈춘다" do
    css = Rails.root.join("app/assets/tailwind/application.css").read

    assert_match(/\.elephant__whole \{ animation: elephant-step 0\.8s ease-in-out infinite alternate; \}/, css)
    assert_match(/\.elephant__shadow \{ animation: elephant-shadow 0\.8s ease-in-out infinite alternate; \}/, css)
    assert_match(/translateY\(-3px\)/, css)
    assert_match(/scaleX\(0\.94\)/, css)
    assert_match(/prefers-reduced-motion: no-preference\) \{\s*\.elephant__whole \{ animation/, css, "움직임을 줄여도 걷는다")
    assert_match(/\.elephant--walking \{ transition: left 1s ease-out, top 1s ease-out; \}/, css)
  end

  test "흰빛이 바뀐 날의 첫 화면에서만 어제 자리에서 걸어온다" do
    @user.rests.create!(rested_on: @user.today, duration: "a_while")

    get new_sitting_path
    assert_select ".elephant-field[data-elephant-moving-value=true]", count: 1

    get new_sitting_path
    assert_select ".elephant-field[data-elephant-moving-value=false]", count: 1, message: "같은 날 두 번 걸어온다"
  end

  test "코끼리는 골라 둔 자리와 무관하다" do
    @user.sittings.create!(mode: "sitting", abiding: @abidings.fetch(8), ended_at: Time.current)

    get new_sitting_path

    reading = Elephant.for(@user)
    assert_select ".elephant-field[data-elephant-whiteness-value=?]", reading.whiteness.to_s
    assert_operator reading.station, :<, 8, "골라 둔 자리가 코끼리를 옮겼다"
  end

  private
    def visible_text = Nokogiri::HTML(response.body).css("body").text.gsub(/\s+/, " ")
end

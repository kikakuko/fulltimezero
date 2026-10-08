# This app is a raft. — 이 앱도 뗏목이다.
#
# 코끼리의 길 — 앉기의 자리 맨 위. 흔적이지 경지가 아니다.
require "test_helper"
require_relative "../../test_helpers/copy_locks"

class ElephantFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @abidings = nine_abidings
    sign_in_as @user
  end

  test "앉기 맨 위에 코끼리의 길이 있고, 굽이에는 이름이 없다" do
    get new_sitting_path

    assert_select ".elephant-field [data-controller=elephant]", count: 0
    assert_select ".elephant-field[data-controller=elephant]", count: 1
    assert_select ".elephant-field__station", false, "굽이에 이름이 붙었다"
    assert_select "a.elephant-field__stop", false, "굽이가 눌러 가는 길이 되었다"
    assert_select ".elephant-place .elephant svg.elephant__art[role=img][aria-label]", count: 1
    assert_select ".elephant-place .elephant.elephant--walking-legs", count: 1

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

  test "흰빛은 그림의 색으로만 보이고, 양 끝은 상수다" do
    css = Rails.root.join("app/assets/tailwind/application.css").read

    assert_match(/--elephant-dark: 0\.35;/, css)
    assert_match(/--elephant-light: 2\.4;/, css)
    assert_match(%r{--elephant-width: calc\(80 / 390 \* 100%\);}, css, "코끼리 폭이 그림 폭의 비율이 아니다")
    assert_match(/\.elephant-field \{[^}]*aspect-ratio: 864 \/ 1184;/m, css, "산수 틀이 그림의 비율이 아니다 — 위에 덧댄 자리가 있다")
    assert_no_match(/ROOM|20000%/, css, "틀 위에 덧댄 자리가 남아 있다")
    assert_match(/--e-light: calc\(\(var\(--elephant-dark\) \+ var\(--ele, 0\) \* \(var\(--elephant-light\) - var\(--elephant-dark\)\)\) \/ var\(--elephant-light\)\);/, css)
    assert_match(/--e-fill: color-mix\(in srgb, var\(--paper\) calc\(var\(--e-light\) \* 100%\), var\(--ink\)\);/, css)

    get new_sitting_path
    assert_select ".elephant-place .elephant[style=?]", "--ele: #{Elephant.for(@user).whiteness.round(4)};"
  end

  test "앵커는 그리는 쪽과 재는 쪽이 같다" do
    js = Rails.root.join("app/javascript/controllers/elephant_controller.js").read
    anchors = js[/export const ANCHORS = \[(.*?)\n\]/m, 1].scan(/\[ (\d+), (\d+) \]/).map { |x, y| [ x.to_i, y.to_i ] }

    assert_equal Elephant::ANCHORS, anchors
    assert_equal Elephant::VIEW, js[/export const VIEW = \[ (\d+), (\d+) \]/, 0].scan(/\d+/).map(&:to_i)
    assert_no_match(/ROOM/, js, "틀 위에 덧댄 자리가 스크립트에 남아 있다")
    assert_no_match(/getPointAtLength/, js, "길 위의 점을 잰다 — 코끼리는 길 위를 가지 않는다")

    # 굽이는 정거장과 따로 산다 — 정거장 아홉은 그대로, 길 점만 그림을 따른다.
    assert_match(/export const BENDS = \{/, js)
    assert_match(/catmullRom\(road\(ANCHORS, BENDS\)\)/, js, "굽이가 길에 끼지 않는다")
    assert_equal 9, anchors.size, "정거장이 아홉이 아니다"

    # 앵커는 그림 안에 있고, 아래에서 위로 오른다.
    Elephant::ANCHORS.each { |x, y| assert x.between?(0, Elephant::VIEW[0]) && y.between?(0, Elephant::VIEW[1]) }
    assert_equal Elephant::ANCHORS.map(&:last).sort.reverse, Elephant::ANCHORS.map(&:last), "길이 올라가지 않는다"
  end

  # 문턱 — 들어설 때 가장자리 밖에서 바위까지 걸어온다. 자리의 변화가 아니라 들어섬에
  # 붙은 움직임이다. 바위 앞에 서면 걸음을 거두고 뒤척임을 시작한다.
  test "선방에 들어서면 가장자리에서 바위까지 걸어와 뒤척인다" do
    css = Rails.root.join("app/assets/tailwind/application.css").read
    js = Rails.root.join("app/javascript/controllers/elephant_controller.js").read

    get new_sitting_path
    assert_select ".elephant-field[data-elephant-arriving-value=true]", count: 1
    assert_select ".elephant-place.elephant-place--arriving .elephant.elephant--walking-legs", count: 1,
      message: "걸어오며 다리를 걷지 않는다"

    assert_match(/\.elephant-place--arriving \{ transform: translate\(calc\(-50% \+ var\(--arrive-from\)\), -100%\); \}/, css)
    assert_match(/transition: transform var\(--arrive-time\) ease-out/, css, "문턱이 걸음이 아니라 튕김이다")
    assert_match(/transitionend.*this\.settle\(\)/m, js, "바위 앞에 서도 걸음을 거두지 않는다")
    assert_match(/settle\(\) \{.*?remove\("elephant--walking-legs"\).*?add\("elephant--restless"\)/m, js,
      "바위 앞에서 뒤척임이 시작되지 않는다")
    assert_no_match(/requestAnimationFrame\(\s*function|setInterval/, js, "스크립트가 걸음을 매 프레임 그린다")
  end

  test "움직임을 끈 사람에게는 처음부터 바위 앞에 서 있다" do
    css = Rails.root.join("app/assets/tailwind/application.css").read
    reduced = css[/@media \(prefers-reduced-motion: reduce\) \{[^@]*?\.elephant-place--arriving[^}]*\}/m].to_s

    assert_match(/transform: translate\(-50%, -100%\)/, reduced, "움직임을 꺼도 가장자리에서 온다")
    assert_match(/matchMedia\("\(prefers-reduced-motion: reduce\)"\)\.matches/,
      Rails.root.join("app/javascript/controllers/elephant_controller.js").read)
  end

  # 앉는 중에는 걸어오지 않는다 — 앉은 채 뒤척일 뿐이다.
  test "앉는 중의 코끼리는 걸어오지 않고 처음부터 뒤척인다" do
    post sittings_path, params: { sitting: { length: "tea" } }
    follow_redirect!

    assert_select ".night .elephant-field[data-elephant-arriving-value=false]", count: 1
    assert_select ".night .elephant-place--arriving", false, "앉는 중에 걸어온다"
    assert_select ".night .elephant.elephant--restless", count: 1, message: "앉는 중에 뒤척이지 않는다"
    assert_select ".night .elephant--walking-legs", false, "앉는 중에 걷는다"
  end

  # 끝에 닿는 일이 없으므로 멎는 자리도 없다. 오래 앉아도 뒤척임 한 점은 남는다(§2).
  test "오래 앉아도 뒤척임 한 점은 남는다 — 끝이 없기 때문이다" do
    at = @user.today.in_time_zone(@user.time_zone).change(hour: 7)
    @user.sittings.create!(mode: "sitting", sat_on: @user.today, created_at: at, ended_at: at + 5000.hours)

    get new_sitting_path
    field = css_select(".elephant-field").first

    assert_match(/--restless: 0\.03;/, field["style"], "뒤척임이 바닥 아래로 내려갔다")
    assert_operator Elephant.for(@user).whiteness, :<, 1.0, "흰빛이 하나에 닿았다"
  end

  test "코끼리는 골라 둔 자리와 무관하다" do
    @user.sittings.create!(mode: "sitting", abiding: @abidings.fetch(8), ended_at: Time.current)

    get new_sitting_path

    reading = Elephant.for(@user)
    assert_match(/--whiteness: #{reading.whiteness.round(4)};/, css_select(".elephant-field").first["style"])
    assert_operator reading.whiteness, :<, 0.01, "골라 둔 자리가 코끼리를 희게 했다"
  end

  private
    def visible_text = Nokogiri::HTML(response.body).css("body").text.gsub(/\s+/, " ")
end

# This app is a raft. — 이 앱도 뗏목이다.
#
# 코끼리의 길 — 앉기의 자리 맨 위. 흔적이지 경지가 아니다.
require "test_helper"
require_relative "../test_helpers/copy_locks"

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
    @abidings.each do |abiding|
      assert_select "a.elephant-field__stop[href=?] .elephant-field__station", abiding_path(abiding), text: abiding.ko
    end
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

  # 주어는 코끼리다. 정거장은 지명이지 사용자의 경지가 아니다.
  test "카드의 주어는 코끼리고, 읽는 이를 부르지 않는다" do
    I18n.available_locales.each do |locale|
      get new_sitting_path(locale: locale)

      card = I18n.t("sittings.elephant.card", station: "x", line: "y", locale: locale)
      assert_match(/\A(코끼리가|The elephant)/, card)
      assert_no_match(CopyLocks.pattern(:addressing), card, "#{locale} 카드가 읽는 이를 부른다")
      # 이름은 어려운 말 그대로(한자 곁에), 곁에 늘 그 자리의 한 줄.
      first = @abidings.first
      expected = I18n.with_locale(locale) do
        I18n.t("sittings.elephant.card", station: "#{first.name}(#{first.han})", line: first.one_line_here)
      end
      assert_select ".quote", text: expected, count: 1
    end
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
    assert_match(/getPointAtLength/, js, "길 위의 점을 재지 않는다")

    # 굽이는 정거장과 따로 산다 — 정거장 아홉은 그대로, 길 점만 그림을 따른다.
    assert_match(/export const BENDS = \{/, js)
    assert_match(/catmullRom\(road\(ANCHORS, BENDS\)\)/, js, "굽이가 길에 끼지 않는다")
    assert_equal 9, anchors.size, "정거장이 아홉이 아니다"

    # 앵커는 그림 안에 있고, 아래에서 위로 오른다.
    Elephant::ANCHORS.each { |x, y| assert x.between?(0, Elephant::VIEW[0]) && y.between?(0, Elephant::VIEW[1]) }
    assert_equal Elephant::ANCHORS.map(&:last).sort.reverse, Elephant::ANCHORS.map(&:last), "길이 올라가지 않는다"
    # 아홉째의 코끼리는 봉우리를 밟지 않는다 — 코끼리 한 마리 높이(그림 좌표 124)가 그 위에
    # 들어야 머리가 틀 안에 온전히 든다. 그림 높이의 11% 아래.
    assert_operator Elephant::ANCHORS.last.last, :>=, (Elephant::VIEW[1] * 0.11).ceil, "아홉째가 봉우리에 올라 머리가 틀 밖으로 나간다"
  end

  # 코끼리는 길 위에서 걷는다. 흰빛이 바뀐 날 곡선 위를 가는 동안에도 걸음은 이어진다.
  test "걸음은 부위별로 이어지고, 길 위를 가는 동안에도 멈추지 않는다" do
    css = Rails.root.join("app/assets/tailwind/application.css").read

    assert_match(/\.elephant-place--walking \{ transition: left 1s ease-out, top 1s ease-out; \}/, css)
    assert_match(/\.elephant--walking-legs \.elephant__leg-fr,\s*\.elephant--walking-legs \.elephant__leg-bl \{ animation: elephant-leg var\(--elephant-stride\) ease-in-out infinite; \}/, css)
    assert_no_match(/elephant-place--walking[^{]*\{[^}]*animation/, css, "길 위를 가는 동안 걸음이 따로 멈춘다")

    js = Rails.root.join("app/javascript/controllers/elephant_controller.js").read
    assert_match(/classList\.add\("elephant-place--walking"\)/, js)
    assert_no_match(/requestAnimationFrame\(\s*function|setInterval|--whiteness/, js, "스크립트가 걸음을 매 프레임 그린다")
  end

  # 아홉째는 등지(等持) — 애써 붙들지 않아도 흔들리지 않는 자리. 흩어지지 않고 흰빛
  # 1 로 온전히 서되, 걸음을 멈춘다. 걷다가 서는 것이 유일한 표시다.
  test "아홉째 정거장에 닿으면 걸음을 멈추고 온전히 선다 — 닿는 날은 올라온 뒤에 선다" do
    Elephant::WINDOW_DAYS.times { |i| @user.rests.create!(rested_on: @user.today - i, duration: "a_while") }
    assert_equal Elephant::STATIONS - 1, Elephant.for(@user).station

    get new_sitting_path
    assert_select ".elephant-place[data-halt=true] .elephant.elephant--walking-legs", count: 1

    get new_sitting_path
    assert_select ".elephant-place[data-halt=false] .elephant", count: 1
    assert_select ".elephant-place .elephant--walking-legs", false, "아홉째에서도 걷는다"
    assert_select ".elephant-place .elephant[style=?]", "--ele: 1.0;"

    js = Rails.root.join("app/javascript/controllers/elephant_controller.js").read
    assert_match(/dataset\.halt === "true".*transitionend.*this\.halt\(\)/m, js, "올라온 뒤에 서지 않는다")
    assert_match(/halt\(\) \{\s*this\.figureTarget\.querySelector\("\.elephant"\)\?\.classList\.remove\("elephant--walking-legs"\)/, js)

    @user.rests.destroy_all
    get new_sitting_path
    assert_select ".elephant-place .elephant--walking-legs", count: 1, message: "아홉째가 아닌데 서 있다"
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

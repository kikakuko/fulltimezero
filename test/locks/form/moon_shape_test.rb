# This app is a raft. — 이 앱도 뗏목이다.
#
# 달의 모양 — **비어 있는 쪽이 오른쪽이다.** 어느 날에도 기우는 달의 모양을 쓰지 않는다(§2).
#
# 달은 비워 그린다. 쉰 만큼 먹이 빠진다. 날이 창 밖으로 밀려나면 그믐 쪽으로
# 돌아가지만, 그때도 모양은 차오르는 달이다 — 오른쪽이 비는 초승이지, 왼쪽이
# 비는 그믐달이 아니다. 시간의 소진이 아니라 고요의 익어감이 이 앱의 문법이다.
#
# 「얼마나 찼는가」는 기능이고(moon_phase_test), 「어느 쪽이 비는가」는 결이다.
require "test_helper"

class MoonShapeTest < ActionView::TestCase
  include MoonHelper

  # 왼쪽 반원은 늘 어두운 자리다. 가리개가 반달 이전에는 어둠을 오른쪽으로 넓히고,
  # 반달 이후에는 왼쪽에서 덜어낸다. 움직이는 것은 가로 반지름뿐이다.
  test "비어 있는 쪽은 언제나 오른쪽이다 — 어느 날에도" do
    [ 0.0, 0.05, 0.25, 0.49, 0.5, 0.51, 0.75, 0.95, 1.0 ].each do |phase|
      mask = Nokogiri::HTML(moon_svg(phase, size: 100)).at_css("mask")
      rect, shade = mask.at_css("rect"), mask.at_css("ellipse")

      assert_equal "0", rect["x"], "어둠의 자리가 왼쪽 반원이 아니다(#{phase})"
      assert_equal "50.0", rect["width"]
      assert_equal "white", rect["fill"], "왼쪽 반원이 비어 있다 — 비는 쪽이 왼쪽이다(#{phase})"
      assert_equal "50.0", shade["cx"], "가리개가 한가운데에 서지 않는다(#{phase})"
      assert_equal "50.0", shade["ry"], "가리개가 세로로 줄었다 — 기우는 모양이다(#{phase})"
    end
  end

  test "차오를수록 어둠이 걷힌다 — 덜 찬 날도 같은 모양이다" do
    seen = [ 0.0, 0.25, 0.5, 0.75, 1.0 ].map do |phase|
      mask = Nokogiri::HTML(moon_svg(phase, size: 100)).at_css("mask")
      [ mask.at_css("ellipse")["rx"].to_f, mask.at_css("ellipse")["fill"] ]
    end

    assert_equal %w[white white black black black], seen.map(&:last),
      "반달을 지나며 가리개가 어둠에서 비움으로 바뀌지 않는다"
    # 반달의 경계는 자를 댄 직선이 되지 않는다 — 가로 반지름의 바닥이 한 점 남는다.
    assert_equal [ 50.0, 25.0, MoonHelper::LEAST_RX, 25.0, 50.0 ], seen.map(&:first),
      "가리개가 한가운데에서 좌우로 열리지 않는다"
    assert_operator MoonHelper::LEAST_RX, :>, 0
  end

  # 그리는 것은 어두운 쪽 하나와 가리개 하나, 그리고 몸체를 잡는 먹선 원이다.
  # 밝은 쪽은 채우지 않는다 — 보름은 먹선 원 하나에 속이 빈 일원상이다.
  test "달은 비워 그린다 — 어두운 쪽 하나 · 가리개 하나 · 먹선 원 하나" do
    svg = Nokogiri::HTML(moon_svg(0.4, size: 100))

    assert_equal 1, svg.css("mask ellipse").size
    assert_equal 1, svg.css("circle.disc").size
    assert_equal 1, svg.css("circle.rim").size
    assert_equal "none", svg.at_css("circle.rim")["fill"], "몸체의 원이 채워져 있다"
    assert_equal "1", svg.at_css("circle.rim")["stroke-width"], "먹선이 가늘지 않다"
    assert_empty svg.css("path"), "달에 획이 들어왔다"
    assert_empty svg.css("circle.moonglow"), "보름이 아닌데 빛이 핀다"

    css = Rails.root.join("app/assets/tailwind/application.css").read
    assert_match(/\.moon circle\.disc \{ opacity: var\(--moon-dark\); \}/, css, "어두운 쪽이 옅은 먹이 아니다")
    assert_match(/\.moon circle\.rim \{ opacity: var\(--moon-rim\); \}/, css)
    root = css[/:root \{.*?\n\}/m]
    %w[--moon-dark --moon-rim --moon-glow].each { |name| assert_match(/#{name}: 0\.\d+;/, root, "#{name} 가 :root 에 없다") }
    # 밤은 먹 바른 종이, 달은 먹을 비운 자리 — 밤에도 비는 쪽이 종이다. 어두운 쪽은 밤 바탕
    # 그대로이되 기껏해야 한지빛 몇 푼이다.
    night = root[/--moon-dark-night: (\d+)%;/, 1]
    assert night, "--moon-dark-night 가 :root 에 없다"
    assert_operator night.to_i, :<=, 10, "밤의 어두운 쪽이 한지빛으로 너무 밝다"
    assert_match(/\.night \.moon circle\.body \{ fill: var\(--paper\); \}/, css, "밤에 비는 쪽이 종이가 아니다")
    assert_match(/\.night \.moon circle\.disc \{ fill: color-mix\(in srgb, var\(--paper\) var\(--moon-dark-night\), var\(--night\)\); opacity: 1; \}/, css)
    assert_equal "none", svg.at_css("circle.body")["fill"], "낮에 밝은 쪽을 채운다"
  end

  # 보름의 빛은 금빛 테두리가 아니라 먹선 원 바깥의 옅은 번짐 한 겹이다. 빈 원은 비워 둔다.
  test "보름의 빛은 먹선 원 바깥에 옅은 금빛 번짐 한 겹이다" do
    svg = Nokogiri::HTML(moon_svg(1.0, size: 100, moonlight: true))
    glow = svg.at_css("circle.moonglow")

    assert glow, "보름에 빛이 없다"
    assert_equal "none", glow["fill"], "빛이 빈 원을 채운다"
    assert_equal "var(--gilt)", glow["stroke"]
    assert_equal "black", svg.at_css("mask ellipse")["fill"], "보름인데 어둠이 남아 있다"
    assert_match(/\.moon circle\.moonglow \{[^}]*filter: blur\(/, Rails.root.join("app/assets/tailwind/application.css").read, "빛이 번지지 않고 테두리가 된다")
  end
end

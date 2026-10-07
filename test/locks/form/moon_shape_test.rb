# This app is a raft. — 이 앱도 뗏목이다.
#
# 달의 모양 — **오른쪽이 밝다.** 어느 날에도 기우는 달의 모양을 쓰지 않는다(§2).
#
# 달이 덜 차는 일은 있다. 날이 창 밖으로 밀려나면 그믐 쪽으로 돌아간다. 다만
# 그때도 모양은 차오르는 달이다 — 오른쪽이 밝은 초승이지, 왼쪽이 밝은 그믐달이
# 아니다. 시간의 소진이 아니라 고요의 익어감이 이 앱의 문법이다.
#
# 「얼마나 찼는가」는 기능이고(moon_phase_test), 「어느 쪽이 밝은가」는 결이다.
require "test_helper"

class MoonShapeTest < ActionView::TestCase
  include MoonHelper

  # 오른쪽 반원은 늘 빛의 자리다. 가리개가 반달 이전에는 그 빛을 덜어내고,
  # 반달 이후에는 왼쪽으로 넓힌다. 움직이는 것은 가로 반지름뿐이다.
  test "밝은 쪽은 언제나 오른쪽이다 — 어느 날에도" do
    [ 0.0, 0.05, 0.25, 0.49, 0.5, 0.51, 0.75, 0.95, 1.0 ].each do |phase|
      mask = Nokogiri::HTML(moon_svg(phase, size: 100)).at_css("mask")
      rect, shade = mask.at_css("rect"), mask.at_css("ellipse")

      assert_equal "50.0", rect["x"], "빛의 자리가 오른쪽 반원이 아니다(#{phase})"
      assert_equal "50.0", rect["width"]
      assert_equal "white", rect["fill"], "오른쪽 반원이 어둡다(#{phase})"
      assert_equal "50.0", shade["cx"], "가리개가 한가운데에 서지 않는다(#{phase})"
      assert_equal "50.0", shade["ry"], "가리개가 세로로 줄었다 — 기우는 모양이다(#{phase})"
    end
  end

  test "차오를수록 가리개가 걷힌다 — 덜 찬 날도 같은 모양이다" do
    seen = [ 0.0, 0.25, 0.5, 0.75, 1.0 ].map do |phase|
      mask = Nokogiri::HTML(moon_svg(phase, size: 100)).at_css("mask")
      [ mask.at_css("ellipse")["rx"].to_f, mask.at_css("ellipse")["fill"] ]
    end

    assert_equal %w[black black white white white], seen.map(&:last),
      "반달을 지나며 가리개가 빛으로 바뀌지 않는다"
    assert_equal [ 50.0, 25.0, 0.0, 25.0, 50.0 ], seen.map(&:first),
      "가리개가 한가운데에서 좌우로 열리지 않는다"
  end

  # 그리는 것은 원 하나와 가리개 하나다. 다른 도형이 끼어들면 모양이 흔들린다.
  test "달은 원 하나와 가리개 하나로 그린다" do
    svg = Nokogiri::HTML(moon_svg(0.4, size: 100))

    assert_equal 1, svg.css("mask ellipse").size
    assert_equal 1, svg.css("circle.disc").size
    assert_empty svg.css("path"), "달에 획이 들어왔다"
  end
end

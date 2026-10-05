# This app is a raft. — 이 앱도 뗏목이다.
#
# 움직임의 결. 닿는 것은 넘쳤다 돌아온다. 빛과 사라짐은 그러지 않는다.
#
# 넘침(--ease-land)은 보상의 말투라 앱 전체에 쓰지 않는다. 물체가 도착하는 순간에만 쓴다 —
# 미륵이 솟아 멈출 때, 한 자가 탑의 칸에 앉을 때. 문 셋의 빛 · 매일의 문 · 코끼리의 걸음 ·
# 무위의 흩어짐 · 하루의 때는 빛이거나 사라짐이라 넘치지 않는다.
# 「결」 쪽 자물쇠다 — 방향을 틀면 풀 수 있다.
require "test_helper"

class MotionTest < ActiveSupport::TestCase
  CSS = Rails.root.join("app/assets/tailwind/application.css")
  # 넘침이 닿아서는 안 되는 자리 — 빛, 걸음, 흩어짐, 하루의 때.
  NEVER_LAND = /gates|daily-door|__light|__flood|__veil|elephant-place|elephant--walking|void__|daylight/

  test "곡선과 시간차가 :root 상수다" do
    root = CSS.read[/:root \{.*?\n\}/m]

    assert_match(/--ease-land: cubic-bezier\(0\.34, 1\.56, 0\.64, 1\);/, root, "닿는 곡선이 :root 에 없다")
    assert_match(/--ease-light: cubic-bezier\([\d., ]+\);/, root, "빛의 곡선이 :root 에 없다")
    assert_match(/--press: 0\.1s;/, root, "누르는 반응이 :root 상수가 아니다")
    assert_match(/--stagger: (?:5\d|6\d|7\d|80)ms;/, root, "시간차가 50~80ms 의 :root 상수가 아니다")
  end

  test "넘침은 도착에만 — 빛 · 걸음 · 흩어짐 · 하루의 때에 닿지 않는다" do
    landed = rules.select { |_, body| body.include?("var(--ease-land)") || body.match?(/cubic-bezier\(0?\.34/) }

    assert_not_empty landed, "넘치는 곡선을 쓰는 곳이 없다"
    landed.each do |selector, _|
      assert_no_match NEVER_LAND, selector, "넘치는 곡선이 빛 · 걸음 · 흩어짐에 닿았다: #{selector}"
    end
    places = landed.map { |selector, _| selector }.join(" ")
    assert_match(/maitreya/, places, "미륵이 솟아 멈추는 자리에 넘침이 없다")
    assert_match(/pagoda__settling/, places, "한 자가 앉는 자리에 넘침이 없다")
  end

  test "넘치는 곡선을 값으로 적지 않는다 — :root 한 곳에서만 온다" do
    rest = CSS.read.sub(/:root \{.*?\n\}/m, "")

    assert_no_match(/cubic-bezier\(\s*0?\.34\s*,\s*1\.56/, rest, "넘치는 곡선이 규칙 안에 박혀 있다")
    scripts = Rails.root.glob("app/javascript/**/*.js").map(&:read).join
    assert_no_match(/cubic-bezier/, scripts, "스크립트가 곡선을 제 손으로 적는다")
    assert_match(/getPropertyValue\("--ease-land"\)/, scripts, "스크립트가 :root 의 곡선을 읽지 않는다")
  end

  test "누르는 반응은 0.1초 안에 — 어디서 눌러도 같다" do
    pressed = rules.find { |selector, _| selector.include?("button:active") }

    assert pressed, "누르는 반응이 없다"
    assert_match(/transition-duration: var\(--press\)/, pressed.last, "누름이 0.1초 상수를 쓰지 않는다")
  end

  private
    def rules
      CSS.read.gsub(%r{/\*.*?\*/}m, "").sub(/:root \{.*?\n\}/m, "")
         .scan(/([^{}]+)\{([^{}]*)\}/).map { |selector, body| [ selector.strip, body ] }
    end
end

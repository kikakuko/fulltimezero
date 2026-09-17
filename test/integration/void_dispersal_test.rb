# This app is a raft. — 이 앱도 뗏목이다.
#
# 무위의 코끼리 — 들면 천천히 흩어져 사라지고, 잠깐 오색이 번진 뒤 어둠.
# 쌓아서 닿는 상태가 아니다. 누구든 매번 본다. 흰빛과 무관하다.
require "test_helper"

class VoidDispersalTest < ActionDispatch::IntegrationTest
  CSS = Rails.root.join("app/assets/tailwind/application.css")
  JS = Rails.root.join("app/javascript/controllers/dispersal_controller.js")
  VIEW = Rails.root.join("app/views/sittings/nothing.html.erb")

  setup { sign_in_as users(:one) }

  test "무위에 들면 코끼리가 있고, 그 밖은 그대로다 — 달도 끝도 없다" do
    post nothing_path
    follow_redirect!

    assert_select ".void .void__scene[data-controller=dispersal] img.void__whole[src*=elephant]", count: 1
    assert_select ".void .moon", false
    assert_select ".void .elephant-field", false
    assert_match I18n.t("nothing.line"), response.body
  end

  test "누구든 매번 본다 — 조건도, 흰빛도, 본 적의 기록도 없다" do
    view = VIEW.read
    js = JS.read

    assert_no_match(/<%\s*(if|unless)|whiteness|Elephant/, view, "무위의 코끼리에 조건이 붙었다")
    assert_no_match(/whiteness|localStorage|sessionStorage|document\.cookie|fetch\(/, js, "흩어짐이 무엇을 읽거나 적는다")
    assert_no_match(/--whiteness/, CSS.read[/\.void__elephant \{[^}]*\}/])
  end

  test "여덟에서 열두 초 사이에 흩어진다" do
    js = JS.read
    still, spread, drift = %w[STILL SPREAD DRIFT].map { |name| js[/const #{name} = (\d+)/, 1].to_i }

    assert_includes 8000..12000, still + spread + drift
  end

  test "오색은 :root 에서 오고, 주사가 아니다" do
    css = CSS.read
    bloom = css[/\.void__bloom \{.*?\n\}/m]

    %w[--dancheong-green --obang-red --dancheong-ocher --night-ink --night-deep].each do |token|
      assert_includes bloom, "var(#{token})"
    end
    assert_no_match(/--cinnabar/, bloom)
    assert_not_equal css[/--cinnabar: (#\h+)/, 1], css[/--obang-red: (#\h+)/, 1]
    assert_match(/@keyframes void-bloom \{\s*0% \{ opacity: 0;.*100% \{ opacity: 0;/m, css, "오색이 남는다 — 이내 어둠이어야 한다")
  end

  test "움직임을 줄이면 흩어지지 않고 그 자리에서 옅어진다" do
    assert_match(/prefers-reduced-motion: reduce.*void__scene--still.*return/m, JS.read)
    assert_match(/\.void__scene--still \.void__whole \{ animation: void-fade/, CSS.read)
  end
end

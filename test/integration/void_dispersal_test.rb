# This app is a raft. — 이 앱도 뗏목이다.
#
# 무위의 코끼리 — 들면 천천히 흩어져 사라지고, 잠깐 오색이 번진 뒤 어둠.
# 쌓아서 닿는 상태가 아니다. 누구든 매번 본다. 흰빛과 무관하다.
require "test_helper"

class VoidDispersalTest < ActionDispatch::IntegrationTest
  CSS = Rails.root.join("app/assets/tailwind/application.css")
  VIEW = Rails.root.join("app/views/sittings/nothing.html.erb")

  setup { sign_in_as users(:one) }

  def root = CSS.read[/:root \{.*?\n\}/m]

  test "무위에 들면 부위별 코끼리가 있고, 그 밖은 그대로다 — 달도 끝도 없다" do
    post nothing_path
    follow_redirect!

    assert_select ".void .void__scene .void__elephant .elephant svg.elephant__art", count: 1
    assert_select ".void .void__elephant .elephant[style]", false, "무위의 코끼리에 흰빛이 실렸다"
    assert_select ".void .void__elephant img", false
    assert_select ".void .moon", false
    assert_select ".void .elephant-field", false
    assert_match I18n.t("nothing.line"), response.body
  end

  test "누구든 매번 본다 — 조건도, 흰빛도, 본 적의 기록도 없다" do
    view = VIEW.read

    assert_no_match(/<%\s*(if|unless)|whiteness|Elephant|ele:/, view, "무위의 코끼리에 조건이 붙었다")
    assert_not Rails.root.join("app/javascript/controllers/dispersal_controller.js").exist?, "흩어짐에 스크립트가 남아 있다"
    assert_match(/\.void__elephant \.elephant \{ --ele: var\(--void-elephant\); \}/, CSS.read)
  end

  test "꼬리부터 코까지 차례로, 여덟에서 열두 초 사이에 흩어진다" do
    seconds = ->(name) { root[/--void-#{name}: ([\d.]+)s;/, 1].to_f }
    total = seconds.("still") + 8 * seconds.("step") + seconds.("drift")
    assert_includes 8.0..12.0, total

    css = CSS.read
    order = %w[tail leg-br leg-bl body leg-fr leg-fl head tusk trunk]
    order.each_with_index do |part, index|
      assert_match(/\.void__elephant \.elephant__#{part} \{ --void-order: #{index};/, css, "#{part} 의 차례가 어긋났다")
    end
    assert_match(/\.void__elephant \.e-ink \{ animation: void-ink calc\(var\(--void-drift\) \* 0\.45\)/, css, "먹선이 먼저 풀리지 않는다")
    assert_no_match(/void-piece|void-scatter|void__whole/, css, "조각의 흔적이 남아 있다")
  end

  test "오색은 :root 에서 오고, 주사가 아니다" do
    css = CSS.read
    bloom = css[/\.void__bloom \{.*?\n\}/m]

    %w[--verdigris --obang-red --dancheong-ocher --night-ink --night-deep].each do |token|
      assert_includes bloom, "var(#{token})"
    end
    assert_no_match(/--cinnabar/, bloom)
    assert_not_equal css[/--cinnabar: (#\h+)/, 1], css[/--obang-red: (#\h+)/, 1]
    assert_match(/@keyframes void-bloom \{\s*0% \{ opacity: 0;.*100% \{ opacity: 0;/m, css, "오색이 남는다 — 이내 어둠이어야 한다")
  end

  test "움직임을 줄이면 흩어지지 않고 그 자리에서 옅어진다" do
    css = CSS.read

    assert_match(/prefers-reduced-motion: reduce\) \{\s*\.void__elephant \{ animation: void-fade/, css)
    css.scan(/^.*animation: void-(?:part|ink|bloom|rise|vanish)\b.*$/).each do |line|
      block = css[0, css.index(line)].rpartition("@media").last
      assert_match(/\A \(prefers-reduced-motion: no-preference\)/, block, "움직임을 줄여도 흩어진다: #{line.strip}")
    end
  end
end

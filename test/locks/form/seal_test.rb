# This app is a raft. — 이 앱도 뗏목이다.
#
# 마당의 낙관(落款)의 결 — 백문(白文): 네모 바탕을 찍고 글자 「쉼」을 한지색으로 비운다.
# 가장자리는 자를 댄 선이 아니라 고르지 않게 번진 테(마스크)이고, 누르면 도장이 내려와
# 인주가 조금 번지며 0.5초 안에 멎는다. 자국은 하나다 — 누를 때마다 같은 자리에 찍힌다.
#
# 바탕은 --seal-ink 한 변수에서 온다. 지금은 먹이다 — 주사는 SPIRIT §2 가 「하루에 한 번만,
# 버튼에는 쓰지 않는다」고 못박고 있어, 낙관을 주사로 찍는 것은 결이 아니라 헌법의 일이다.
require "test_helper"

class SealTest < ActionDispatch::IntegrationTest
  CSS = Rails.root.join("app/assets/tailwind/application.css")

  test "낙관은 네모 바탕에 한지색 글자 「쉼」이다 — 번역하지 않고, 그림이 아니다" do
    sign_in_as users(:one)
    get today_path

    assert_select "form#rest button.seal[lang=ko][aria-label]", text: "쉼", count: 1
    assert_select "form#rest img, form#rest svg", false, "낙관에 그림이 들어왔다"
    assert_equal "쉼", I18n.t("today.rested", locale: :en), "낙관을 번역했다"

    css = CSS.read
    seal = css[/\.seal \{[^}]*\}/m]
    assert_match(/border-radius: 3px/, seal, "낙관이 네모가 아니다")
    assert_match(/width: 2\.875rem; height: 2\.875rem/, seal, "낙관의 크기가 44~48px 밖이다")
    assert_match(/background: var\(--seal-ink\); color: var\(--paper\)/, seal, "백문이 아니다 — 바탕을 찍고 글자를 비운다")
    assert_match(/font-family: var\(--serif\)/, seal, "낙관의 글자가 붓이 아니다")
    assert_match(/mask-image: var\(--seal-mask\)/, seal, "가장자리가 자를 댄 선이다 — 마스크가 없다")
    assert_no_match(/border: 1px/, seal)

    root = css[/:root \{.*?\n\}/m]
    assert_match(/--seal-ink: var\(--ink\);/, root, "낙관의 바탕이 먹이 아니다 — 주사는 §2 개정이 먼저다")
    assert_match(/--seal-mask: url\("data:image\/svg\+xml,.*feTurbulence.*feDisplacementMap.*radialGradient/, root,
      "마스크가 잡음으로 테를 흔들고 모서리로 갈수록 옅지 않다")
  end

  test "찍는 움직임은 0.5초 안에 멎고, 움직임을 줄이면 바로 찍힌 자리다" do
    css = CSS.read
    root = css[/:root \{.*?\n\}/m]

    press = root[/--seal-press-time: ([\d.]+)s;/, 1].to_f
    bleed = root[/--seal-bleed-time: ([\d.]+)s;/, 1].to_f
    assert_operator press, :<=, 0.1, "도장이 내려오는 데 0.1초를 넘는다"
    assert_operator press + bleed, :<=, 0.5, "찍힘이 0.5초 안에 멎지 않는다"
    assert_match(/@keyframes seal-press \{\s*0%\s*\{ transform: scale\(1\.08\) rotate\(-2deg\); opacity: 0\.7; \}\s*100%\s*\{ transform: scale\(1\) rotate\(0\); opacity: 1; \}/, css)
    assert_match(/@keyframes seal-bleed \{\s*0%\s*\{ mask-size: 100%;.*100%\s*\{ mask-size: 10[0-9]%;/m, css, "인주가 가장자리로 번지지 않는다")
    %w[seal-press seal-bleed].each do |name|
      css.scan(/^.*animation:[^;]*\b#{name}\b.*$/).each do |line|
        block = css[0, css.index(line)].rpartition("@media").last
        assert_match(/\A \(prefers-reduced-motion: no-preference\)/, block, "움직임을 줄여도 #{name} 가 돈다")
      end
    end
    assert_no_match(/\.rest--stamped[^{]*moon/, css, "찍힐 때 달이 움직인다")
  end

  test "자국은 하나다 — 누를 때마다 같은 자리에 다시 찍힌다" do
    user = users(:one)
    sign_in_as user

    3.times { post rests_path }
    follow_redirect!
    assert_select ".seal", count: 1, message: "자국이 늘거나 겹친다"
    assert_select "form#rest.rest--stamped", count: 1
  end

  test "찍는 손짓의 떨림은 비움과 같은 게이트를 지난다" do
    user = users(:one)
    sign_in_as user
    get today_path

    assert_select "form#rest[data-controller~=seal][data-seal-vibrate-value=?]", SilenceGate.allow?(:vibration, user: user).to_s
    js = Rails.root.join("app/javascript/controllers/seal_controller.js").read
    assert_match(/import \{ touch \} from "lib\/haptics"/, js)
    assert_no_match(/navigator\.vibrate/, js, "게이트를 거치지 않고 떤다")
  end
end

# This app is a raft. — 이 앱도 뗏목이다.
#
# 마당의 낙관 「쉼」의 결 — 붓 한 자가 먹선 원에 앉아 있고, 누르면 살짝 눌리고(0.1초 안),
# 찍힌 뒤 먹이 한 번 번졌다 가라앉는다(1초 안). 달은 움직이지 않는다.
require "test_helper"

class SealTest < ActionDispatch::IntegrationTest
  CSS = Rails.root.join("app/assets/tailwind/application.css")

  test "낙관은 먹선 원에 붓 한 자다 — 그림 기호가 아니다" do
    sign_in_as users(:one)
    get today_path

    assert_select "form#rest button.seal", text: I18n.t("today.rested"), count: 1
    assert_operator I18n.t("today.rested").length, :<=, 2, "낙관의 글자가 한두 자가 아니다"
    assert_select "form#rest img, form#rest svg", false, "낙관에 그림이 들어왔다"

    css = CSS.read
    seal = css[/\.seal \{[^}]*\}/m]
    assert_match(/border-radius: 50%/, seal)
    assert_match(/font-family: var\(--serif\)/, seal, "낙관의 글자가 붓이 아니다")
    assert_match(/border: 1px solid var\(--ink\)/, seal)
  end

  test "눌림은 0.1초 안, 번짐은 1초 안에 걷힌다 — 움직임을 줄이면 둘 다 없다" do
    css = CSS.read
    root = css[/:root \{.*?\n\}/m]

    press = root[/--seal-press-time: ([\d.]+)s;/, 1].to_f
    stamp = root[/--seal-stamp-time: ([\d.]+)s;/, 1].to_f
    assert_operator press, :<=, 0.1, "눌림이 0.1초를 넘는다"
    assert_operator stamp, :<=, 1.0, "번짐이 1초 안에 걷히지 않는다"
    assert_match(/\.seal:active \{ transform: scale\(0\.9\d\); \}/, css, "누르는 순간 눌리지 않는다")
    assert_match(/prefers-reduced-motion: no-preference\) \{\s*\.rest--stamped \.seal::after \{ animation: seal-stamp var\(--seal-stamp-time\)/, css,
      "움직임을 줄여도 번진다")
    assert_match(/@keyframes seal-stamp \{.*?100%\s*\{ opacity: 0;/m, css, "번짐이 가라앉지 않는다")
    assert_no_match(/\.seal[^{]*\{[^}]*box-shadow/, css, "번짐이 그림자다 — 먹이어야 한다")
    assert_match(/prefers-reduced-motion: reduce\) \{\s*\.seal \{ transition: none; \}\s*\.seal:active \{ transform: none; \}/, css)
    assert_no_match(/\.rest--stamped \.moon|\.rest--stamped [^{]*moon/, css, "찍힐 때 달이 움직인다")
  end
end

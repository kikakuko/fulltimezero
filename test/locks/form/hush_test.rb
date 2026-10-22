# This app is a raft. — 이 앱도 뗏목이다.
#
# 머리줄과 아래 문을 물리는 결(docs/M-entry-design.md 3절, 2026-10-22). 전각에 들어선 뒤 3초가
# 지나면 둘이 화면 밖으로 밀려나고(옅어지는 것이 아니다), 손길 · 스크롤 · 포커스에 돌아온다.
# 「숨은 동안 포커스 가능한 요소가 화면 밖에 남지 않는다」는 결이 아니라 접근의 약속에 가깝다 —
# 숨는 것과 inert 가 한 몸이어야 키보드 사용자가 화면 밖의 것에 갇히지 않는다.
require "test_helper"

class HushTest < ActionDispatch::IntegrationTest
  CSS = Rails.root.join("app/assets/tailwind/application.css")
  JS = Rails.root.join("app/javascript/controllers/hush_controller.js")
  HALL_PAGES = %i[new_sitting_path days_path new_copying_path guide_path bows_path bells_path].freeze

  setup do
    heart_sutra
    sign_in_as users(:one)
  end

  def css = CSS.read
  def js = JS.read

  test "숨은 동안 포커스 가능한 요소가 화면 밖에 남지 않는다 — 숨는 것과 inert 가 한 몸이다" do
    # 화면 밖으로 미는 규칙은 [inert] 에만 걸린다 — inert 가 아니면서 밀려나는 길이 없다.
    rules = css.gsub(%r{/\*.*?\*/}m, "").scan(/([^{}]+)\{([^{}]*)\}/).map { |selector, body| [ selector.strip, body ] }
    moving = rules.select { |selector, body| selector.match?(/\.chrome|\.doors/) && body.match?(/translate:\s*0 -?100%/) }
    assert_equal [ ".chrome[inert]", ".doors[inert]" ], moving.map(&:first).sort, "화면 밖으로 미는 규칙이 inert 와 한 몸이 아니다"
    assert_match(/\.chrome\[inert\] \{ translate: 0 -100%; \}/, css, "머리줄이 위로 나가지 않는다")
    assert_match(/\.doors\[inert\] \{ translate: 0 100%; \}/, css, "아래 문이 아래로 나가지 않는다")
    assert_no_match(/\.(?:chrome|doors)(?:\[inert\])? \{[^}]*opacity/, css, "옅기로 숨긴다 — 밀려나는 것이지 옅어지는 것이 아니다")

    # 스크립트는 inert 를 켜고 끄는 것으로만 숨기고 돌아온다.
    assert_match(/away\(\) \{\s*this\.parts\.forEach\(part => \{ part\.inert = true \}\)/m, js, "숨을 때 inert 가 아니다")
    assert_match(/restore\(\) \{[^}]*this\.parts\.forEach\(part => \{ part\.inert = false \}\)/m, js, "돌아올 때 inert 를 풀지 않는다")
    assert_no_match(/classList\.(?:add|toggle)|style\./, js, "inert 밖의 손으로 숨긴다")
    assert_match(/querySelectorAll\("header\.chrome, nav\.doors"\)/, js)
  end

  test "들어선 뒤 삼 초 뒤에 나가고, 손길 · 스크롤 · 포커스에 돌아온다 — 돌아올 때 0.4초" do
    root = css[/:root \{.*?\n\}/m]
    assert_match(/--hush-after: 3s;/, root, "나가는 때가 :root 에 없다")
    assert_match(/--hush-back: 0\.4s;/, root, "돌아오는 시간이 :root 에 없다")
    assert_match(/\.chrome, \.doors \{ transition: translate var\(--hush-away\) ease-in; \}/, css)
    assert_match(/\.chrome:not\(\[inert\]\), \.doors:not\(\[inert\]\) \{ transition-duration: var\(--hush-back\); transition-timing-function: ease-out; \}/, css)
    assert_match(/prefers-reduced-motion: reduce\) \{\s*\.chrome, \.doors \{ transition: none; \}/, css, "움직임을 줄여도 미끄러진다")

    assert_match(/getPropertyValue\("--hush-after"\)/, js, "스크립트가 제 손으로 시간을 적는다")
    assert_no_match(/setTimeout\([^,]+, \d/, js, "스크립트에 밀리초가 박혀 있다")
    assert_match(/const RETURNS = \[ "touchstart", "pointerdown", "scroll", "focusin" \]/, js)
    assert_match(/once: true/, js, "돌아온 뒤에도 손길을 계속 듣는다")
    # 떠날 때 되돌린다 — 스냅숏에 숨은 채로 담기지 않게. 손은 떼고 간다.
    assert_match(/addEventListener\("turbo:before-cache", this\.recall\)/, js)
    assert_match(/removeEventListener\("turbo:before-cache", this\.recall\)/, js)
    assert_match(/disconnect\(\) \{\s*this\.restore\(\)/m, js)
  end

  test "물리는 것은 전각 화면뿐이다 — 마당 · 문 · 앉는 중에는 없다" do
    HALL_PAGES.each do |way|
      get send(way)
      assert_select "body[data-controller=hush]", count: 1, message: "#{way} 에서 머리줄과 문이 물러나지 않는다"
      assert_select "header.chrome", count: 1
      assert_select "nav.doors a.door", count: 4
    end

    get today_path
    assert_select "body[data-controller=hush]", false, "마당에서 머리줄이 물러난다"
    get threshold_path
    assert_select "body[data-controller=hush]", false
    post sittings_path, params: { sitting: { length: "tea" } }
    follow_redirect!
    assert_select "body[data-controller=hush]", false, "앉는 중에 물릴 것이 있다 — 거기엔 문이 없다"
  end
end

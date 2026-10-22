// This app is a raft. — 이 앱도 뗏목이다.
//
// 머리줄과 아래 문을 잠깐 물린다. 전각에 들어서면 그림이 화면을 채운다 — 들어선 뒤 3초가 지나면
// 머리줄은 위로, 아래 문은 아래로 화면 밖으로 밀려난다(옅어지는 것이 아니다). 손길 · 스크롤 ·
// 포커스가 있으면 돌아오고, 돌아온 뒤에는 다시 나가지 않는다. 숨은 동안은 inert 다 — 키보드
// 사용자가 화면 밖의 것에 갇히지 않고, 스크린리더가 화면 밖의 것을 읽지 않는다. 숨었다 돌아오는
// 것은 화면 쪽 일이라 서버는 모른다. 떠날 때는 되돌린다(turbo:before-cache) — 스냅숏에 숨은
// 채로 담기지 않게. 시간은 CSS(--hush-after · --hush-back)에서 온다. 전각 화면의 <body> 에만 선다.
import { Controller } from "@hotwired/stimulus"

// 돌아오게 하는 손길 — 닿음 · 누름 · 스크롤 · 포커스.
const RETURNS = [ "touchstart", "pointerdown", "scroll", "focusin" ]

export default class extends Controller {
  connect() {
    this.parts = [ ...this.element.querySelectorAll("header.chrome, nav.doors") ]
    this.recall = () => this.restore()
    this.timer = setTimeout(() => this.away(), after())
    document.addEventListener("turbo:before-cache", this.recall)
  }

  disconnect() {
    this.restore()
    document.removeEventListener("turbo:before-cache", this.recall)
  }

  // 화면 밖으로. 숨은 것은 inert — 어디서도 닿지 않는다.
  away() {
    this.parts.forEach(part => { part.inert = true })
    RETURNS.forEach(name => document.addEventListener(name, this.recall, { passive: true, once: true }))
  }

  // 돌아온다. 다시 나가지 않는다.
  restore() {
    clearTimeout(this.timer)
    this.parts.forEach(part => { part.inert = false })
    RETURNS.forEach(name => document.removeEventListener(name, this.recall))
  }
}

// 들어선 뒤 얼마나 있다가 — 값은 :root 한 곳에만 있다.
function after() {
  return parseFloat(getComputedStyle(document.documentElement).getPropertyValue("--hush-after")) * 1000 || 0
}

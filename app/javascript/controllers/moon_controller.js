// This app is a raft. — 이 앱도 뗏목이다.
//
// 달이 응답한다. 「쉬었다」를 누른 그 순간, 달의 오늘 몫 — 하루치의 먹 — 이 눈에 보이게
// 빠져 실제 비율에 멎는다. 하루 한 번, 그 순간에만(사건). 경과 시간으로 차오르는 것이
// 아니다 — 서버가 「어디서 어디로」만 준다. 움직이는 것은 가리개의 가로 반지름(--moon-rx)
// 하나이고, 옮아감은 CSS 의 것이다(--moon-fill-time). 숫자는 어디에도 없다.
import { Controller } from "@hotwired/stimulus"

const STEP = 2400 // --moon-fill-time 과 같다. 끝을 알리지 않아도 이 뒤에는 넘어간다

export default class extends Controller {
  static values = { rx: Number, lit: Boolean, least: Number }

  connect() {
    const shade = this.element.querySelector("mask ellipse")
    if (!shade) return

    // 반달을 지나는 날 — 가리개가 어둠(검정)에서 비움(흰빛)으로 바뀐다. 먼저 한 점까지
    // 닫고, 그 자리에서 뒤집은 뒤 다시 연다. 보기에는 한 번의 움직임이다.
    const crossing = this.litValue && shade.getAttribute("fill") !== "white"
    this.frame = requestAnimationFrame(() => requestAnimationFrame(() => {
      if (!crossing) return this.open(this.rxValue)

      this.open(this.leastValue)
      this.after(shade, () => {
        shade.setAttribute("fill", "white") // 가리개를 어둠에서 비움으로 — 색이 아니라 마스크의 밝기다
        this.element.querySelector(".edge-clip")?.setAttribute("x", 0) // 경계가 왼쪽 반으로 건너간다
        this.open(this.rxValue)
      })
    }))
  }

  disconnect() {
    cancelAnimationFrame(this.frame)
    clearTimeout(this.timer)
  }

  open(rx) { this.element.style.setProperty("--moon-rx", `${rx}px`) }

  // 옮아감이 끝나기를 기다린다. 움직임을 줄인 화면에서는 옮아감이 없어 곧장 다음이고,
  // 어떤 까닭으로 끝을 알리지 않아도 제 시간이 지나면 넘어간다.
  after(shade, done) {
    if (matchMedia("(prefers-reduced-motion: reduce)").matches) return done()

    const once = () => { clearTimeout(this.timer); shade.removeEventListener("transitionend", once); done() }
    this.timer = setTimeout(once, STEP + 100)
    shade.addEventListener("transitionend", once)
  }
}

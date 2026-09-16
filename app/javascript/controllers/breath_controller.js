// This app is a raft. — 이 앱도 뗏목이다.
//
// 셋째 문. 손을 얹고 있는 동안 장막이 옅어졌다 짙어지기를 세 번
// (CSS 의 gates-breath, 세 번 되풀이). 손을 떼면 처음부터.
// 세 번이 끝나면 장막이 걷히며 그림 전체가 드러나고(1.6초), 한 숨
// 보여 준 뒤 한지빛 오늘로 옅어진다. 몇 번째인지 보여 주지 않고,
// 잘했다는 말도 하지 않는다.
import { Controller } from "@hotwired/stimulus"

const REVEAL = 1600 // 장막이 걷히는 동안
const LEAVE = 1800  // 그림을 한 숨 보여 주고 옅어지는 동안

export default class extends Controller {
  static targets = ["gate"]

  // 그림은 문을 옮겨 가는 동안 남겨 둔 것이라, 쓸 때마다 찾는다.
  get gates() { return document.getElementById("gates") }
  get veil() { return this.gates?.querySelector(".gates__veil") }

  hold(event) {
    if (this.opening) return
    if (event.target.closest("form, button, a")) return // 「나중에」를 누르는 손은 숨이 아니다.

    event.preventDefault()
    this.gates?.classList.add("gates--breathing")
  }

  // 떼면 처음부터 — 되풀이 셈도 함께 처음으로 돌아간다.
  // 장막이 걷히기 시작한 뒤에는 손을 떼도 그대로 열린다.
  release() {
    if (this.opening) return

    this.gates?.classList.remove("gates--breathing")
  }

  async breathed(event) {
    if (event.target !== this.veil || event.animationName !== "gates-breath") return
    if (this.opening || !this.gates.classList.contains("gates--breathing")) return

    this.opening = true
    this.element.classList.add("opening")
    this.gates.classList.remove("gates--breathing")
    this.veil.dataset.state = "open"
    await settle(this.veil, REVEAL)

    this.gates.classList.add("gates--leaving")
    await settle(this.gates, LEAVE)

    this.gateTarget.requestSubmit()
  }
}

// 옅어짐이 끝나기를 기다린다. 움직임을 줄인 화면에서는 옮아감이 없으므로
// 곧장 넘어가고, 어떤 까닭으로 끝을 알리지 않아도 제 시간이 지나면 넘어간다.
function settle(element, ms) {
  if (matchMedia("(prefers-reduced-motion: reduce)").matches) return Promise.resolve()

  return new Promise(resolve => {
    const done = () => { clearTimeout(timer); element.removeEventListener("transitionend", ended); resolve() }
    const ended = event => { if (event.target === element && event.propertyName === "opacity") done() }
    const timer = setTimeout(done, ms + 200)
    element.addEventListener("transitionend", ended)
  })
}

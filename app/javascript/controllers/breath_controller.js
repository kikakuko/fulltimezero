// This app is a raft. — 이 앱도 뗏목이다.
//
// 셋째 문. 할 일이 없다. 「한 번도 움직인 적 없다」가 떠 있고, 아무것도
// 하지 않아도 잠시 뒤 장막이 스스로 걷힌다 — 그림 전체가 드러나고(1.6초),
// 한 숨 보여 준 뒤 한지빛 오늘로 옅어진다. 버튼도 손도 없다.
// 잘했다는 말도 하지 않는다.
import { Controller } from "@hotwired/stimulus"

const DWELL = 4500  // 한 줄이 떠 있는 동안. 넉 초에서 다섯 초 사이
const REVEAL = 1600 // 장막이 걷히는 동안
const LEAVE = 1800  // 그림을 한 숨 보여 주고 옅어지는 동안

export default class extends Controller {
  static targets = ["gate"]

  // 그림은 문을 옮겨 가는 동안 남겨 둔 것이라, 쓸 때마다 찾는다.
  get gates() { return document.getElementById("gates") }
  get veil() { return this.gates?.querySelector(".gates__veil") }

  connect() {
    this.timer = setTimeout(() => this.open(), DWELL)
  }

  disconnect() { clearTimeout(this.timer) }

  async open() {
    if (this.opening || !this.gates) return

    this.opening = true
    this.element.classList.add("opening")
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

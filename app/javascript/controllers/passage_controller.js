// This app is a raft. — 이 앱도 뗏목이다.
//
// 손님의 지남 — 문 셋을 한 자리에서. 적을 것이 없으니 누를 것도 둘째 · 셋째 문에는
// 없다. 「들어간다」 하나로 빛이 일주문에서 천왕문을 지나 불이문으로 간다 — 작아지고
// 밝아지다가 불이문에서 온통 밝아지면 마당이다. 빛의 길은 CSS(gate-pass · gate-glow)에
// 있고, 여기서는 때가 되면 장막을 다음 문으로 옮기고 마지막에 마당으로 가는 GET 폼을
// 보낼 뿐이다. 잘했다는 말도, 손짓도 없다.
import { Controller } from "@hotwired/stimulus"

// 빛의 길 --light-pass(6.4초)의 때 — 천왕문에 닿는 때 · 불이문에 닿는 때 · 온통 밝은 때 · 마당.
const NAMING_AT = 2200
const BREATH_AT = 4200
const OPEN_AT = 6000
const DONE_AT = 6600

export default class extends Controller {
  static targets = ["gate"]

  // 그림은 문을 옮겨 가는 동안 남겨 둔 것이라, 쓸 때마다 찾는다.
  get gates() { return document.getElementById("gates") }
  get veil() { return this.gates?.querySelector(".gates__veil") }

  enter(event) {
    event?.preventDefault()
    if (this.entering) return
    this.entering = true

    // 움직임을 줄인 화면에서는 빛의 길이 없다 — 곧장 마당이다.
    if (!this.gates || matchMedia("(prefers-reduced-motion: reduce)").matches) return this.gateTarget.requestSubmit()

    this.element.classList.add("passing")
    this.gates.classList.add("gates--passing")
    this.timers = [
      setTimeout(() => this.shift("naming"), NAMING_AT),
      setTimeout(() => this.shift("breath"), BREATH_AT),
      setTimeout(() => this.shift("open"), OPEN_AT),
      setTimeout(() => this.gateTarget.requestSubmit(), DONE_AT)
    ]
  }

  disconnect() { this.timers?.forEach(clearTimeout) }

  // 장막을 다음 문으로 — 지금의 장막을 한 번 읽어 두어야 거기서부터 옮아간다.
  shift(state) {
    const veil = this.veil
    if (!veil) return

    getComputedStyle(veil).opacity
    veil.dataset.state = state
  }
}

// This app is a raft. — 이 앱도 뗏목이다.
//
// 처음의 문 셋 — 그림 위의 장막을 이 문의 상태로 옮긴다.
//
// 그림과 장막은 문을 옮겨 가는 동안 그대로 남는다(data-turbo-permanent).
// 새 문이 들어서면 장막의 상태만 바꾼다 — 그러면 CSS 가 어둠을 1.2초에
// 걸쳐 옮기고, 그림은 한 번도 움직이지 않는다.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { state: String }

  // Turbo 는 남겨 둔 그림을 새 문에 옮겨 붙이는 일을 이 연결보다 조금
  // 늦게 마친다. 한 틀 기다렸다가 장막을 찾는다.
  connect() {
    this.frame = requestAnimationFrame(() => this.shift())
  }

  disconnect() { cancelAnimationFrame(this.frame) }

  shift() {
    const veil = document.querySelector("#gates .gates__veil")
    if (!veil || veil.dataset.state === this.stateValue) return

    getComputedStyle(veil).opacity // 지금의 장막을 한 번 읽어 두어야 거기서부터 옮아간다.
    veil.dataset.state = this.stateValue
  }
}

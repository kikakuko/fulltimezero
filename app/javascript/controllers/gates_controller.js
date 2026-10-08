// This app is a raft. — 이 앱도 뗏목이다.
//
// 처음의 문 셋 — 그림 위의 장막을 이 문의 상태로 옮긴다.
//
// 그림과 장막은 문을 옮겨 가는 동안 그대로 남는다(data-turbo-permanent).
// 새 문이 들어서면 장막의 상태만 바꾼다 — 그러면 CSS 가 어둠을 1.2초에
// 걸쳐 옮기고, 그림은 한 번도 움직이지 않는다.
import { Controller } from "@hotwired/stimulus"

// 빛의 때 — 계정이 없어 시간대를 모를 때 브라우저의 시계로 고른다.
// 경계는 GateLight::HOURS 와 같다. 어떤 빛을 보았는지 적어 두지 않는다.
const HOURS = { dawn: [5, 8], day: [8, 17], evening: [17, 20] }

function lightAt(hour) {
  const found = Object.entries(HOURS).find(([, [from, to]]) => hour >= from && hour < to)
  return found ? found[0] : "night"
}

export default class extends Controller {
  static values = { state: String }

  // Turbo 는 남겨 둔 그림을 새 문에 옮겨 붙이는 일을 이 연결보다 조금
  // 늦게 마친다. 한 틀 기다렸다가 장막을 찾는다.
  connect() {
    this.frame = requestAnimationFrame(() => this.shift())
    // 남겨 두는 그림은 떠날 때 이 문의 상태로 되돌려 스냅숏에 담는다 — 열렸거나 지나는 중이던
    // 장막이 다음에 되살아나지 않게(permanent_test).
    this.restore = () => {
      const veil = document.querySelector("#gates .gates__veil")
      if (veil) veil.dataset.state = this.stateValue
    }
    document.addEventListener("turbo:before-cache", this.restore)
  }

  disconnect() {
    cancelAnimationFrame(this.frame)
    document.removeEventListener("turbo:before-cache", this.restore)
  }

  shift() {
    const gates = document.getElementById("gates")
    if (gates && !gates.dataset.light) gates.dataset.light = lightAt(new Date().getHours())
    // 문에 새로 서는 그림은 지나는 중이 아니다 — 남겨 둔 그림에 그 표시가 묻어 왔어도 걷는다.
    gates?.classList.remove("gates--passing")

    const veil = document.querySelector("#gates .gates__veil")
    if (!veil || veil.dataset.state === this.stateValue) return

    getComputedStyle(veil).opacity // 지금의 장막을 한 번 읽어 두어야 거기서부터 옮아간다.
    veil.dataset.state = this.stateValue
  }
}

// This app is a raft. — 이 앱도 뗏목이다.
//
// 처음의 문 셋 — 그림 위의 장막을 이 문의 상태로 옮기고, 그림을 이 화면의 첫 걸음에 세운다.
//
// 그림과 장막은 문을 옮겨 가는 동안 그대로 남는다(data-turbo-permanent). 새 문이 들어서면 장막의 상태를 바꾸고
// 그 문의 첫 걸음 그림으로 겹쳐 넘어간다 — 첫째 문은 ① 원경, 둘째 문은 ④ 천왕문 왼쪽 벽, 셋째 문은 ⑥ 불이문.
// 새로 고침도 그 화면의 첫 걸음에서 시작한다 — 걸음을 기억해 되살리지 않는다(docs/M-landing-design.md 2절).
// 같은 주소 안의 걸음(① → ②, ④ → ⑤)은 history 에 한 칸씩 쌓아 뒤로 가기가 한 걸음 나옴이 된다 — Turbo 보다
// 먼저 단 손(seonbang_history)이 같은 주소의 걸음을 받는다. 서버에는 묻지 않는다.
import { Controller } from "@hotwired/stimulus"
import { steps as history_steps } from "controllers/seonbang_history"
import { STEPS, showStep, entryTime, reduced } from "controllers/gates_steps"

// 빛의 때 — 계정이 없어 시간대를 모를 때 브라우저의 시계로 고른다.
// 경계는 GateLight::HOURS 와 같다. 어떤 빛을 보았는지 적어 두지 않는다.
const HOURS = { dawn: [5, 8], day: [8, 17], evening: [17, 20] }
const FIRST = { stop: "far", naming: "wall-left", breath: "burimun" }

function lightAt(hour) {
  const found = Object.entries(HOURS).find(([, [from, to]]) => hour >= from && hour < to)
  return found ? found[0] : "night"
}

export default class extends Controller {
  static values = { state: String }

  // Turbo 는 남겨 둔 그림을 새 문에 옮겨 붙이는 일을 이 연결보다 조금
  // 늦게 마친다. 한 틀 기다렸다가 장막과 그림을 찾는다.
  connect() {
    this.url = location.href
    this.handle = state => this.onPop(state)
    history_steps.handle = this.handle
    history.replaceState({ ...history.state, gatesStep: FIRST[this.stateValue] }, "")
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
    clearTimeout(this.timer)
    if (history_steps.handle === this.handle) history_steps.handle = null
    document.removeEventListener("turbo:before-cache", this.restore)
  }

  shift() {
    const gates = document.getElementById("gates")
    if (gates && !gates.dataset.light) gates.dataset.light = lightAt(new Date().getHours())
    // 문에 새로 서는 그림은 지나는 중이 아니다 — 남겨 둔 그림에 그 표시가 묻어 왔어도 걷는다.
    gates?.classList.remove("gates--passing")

    // 이 화면의 첫 걸음으로 — 앞 문에서 넘어왔으면 겹쳐서, 처음 그려졌으면 바로. 이 틀이 늦게 와도(숨은 탭,
    // 느린 기기) 사람이 이미 걸음을 옮겼으면 되돌리지 않는다.
    const first = FIRST[this.stateValue]
    if (gates && !this.moved) showStep(first, { instant: gates.dataset.step === first })

    const veil = document.querySelector("#gates .gates__veil")
    if (!veil || veil.dataset.state === this.stateValue) return

    getComputedStyle(veil).opacity // 지금의 장막을 한 번 읽어 두어야 거기서부터 옮아간다.
    veil.dataset.state = this.stateValue
  }

  get step() { return document.getElementById("gates")?.dataset.step }

  // ① → ② — 원경의 작은 일주문을 가운데로 다가간 뒤(1.6초) 일주문 B 로 겹쳐 바뀐다.
  approach(event) {
    if (this.step !== "far") return
    // 「나중에」는 붙잡지 않는다 — 그 손잡이를 누른 것은 다가감이 아니다.
    if (event?.target.closest?.(".threshold__later, form")) return
    event?.preventDefault()
    this.moved = true
    history.pushState({ ...history.state, gatesStep: "gate" }, "")
    this.toGate()
  }

  toGate() {
    showStep("approach")
    clearTimeout(this.timer)
    this.timer = setTimeout(() => showStep("gate"), entryTime())
  }

  // ④ → ⑤ — 천왕문 안에서 왼쪽 벽을 보고 오른쪽 벽으로.
  walk(event) {
    event?.preventDefault()
    if (this.step !== "wall-left") return
    this.moved = true
    history.pushState({ ...history.state, gatesStep: "wall-right" }, "")
    showStep("wall-right")
  }

  // ② → ③ → 둘째 문 — 「들어간다」. 문을 지나며 D3c 로 겹쳐 바뀐 뒤 둘째 문의 주소로 간다(그 주소는 링크 그대로).
  pass(event) {
    const link = event.currentTarget
    event.preventDefault()
    if (this.passing) return
    this.passing = this.moved = true
    showStep("within")
    setTimeout(() => window.Turbo ? window.Turbo.visit(link.href) : link.click(), entryTime())
  }

  // 같은 주소의 걸음이면 받고 참을 돌려준다(그러면 Turbo 에 가지 않는다).
  onPop(state) {
    const step = state?.gatesStep
    if (!STEPS.includes(step) || location.href !== this.url) return false

    clearTimeout(this.timer)
    this.moved = true
    if (step === "gate" && this.step === "far") this.toGate()
    else showStep(step, { instant: reduced() })
    return true
  }
}

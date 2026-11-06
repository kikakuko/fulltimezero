// This app is a raft. — 이 앱도 뗏목이다.
//
// 선방의 세 걸음 — ① 방(room) → ② 탱화 앞, 크게 보기(near) → ③ 탱화 속(within). docs/M-seonbang-room-design.md.
//
// 걸음은 보는 자리만 바꾼다. 앉음은 한 줄이고, 걸음을 옮겨도 서버에 묻지 않으며, 어느 자리에서 앉았는지 적지
// 않는다(seonbang_steps_test). 그래서 이 손은 data-step 하나를 바꾸고, 뒤로 가기가 한 걸음 나옴이 되게 브라우저의
// 기록에 걸음을 쌓을 뿐이다. 움직임은 CSS 가 한다(걸음마다 --entry-time, 1.6초). 움직임을 줄인 화면은 바로 바뀐다.
//
// 기록 — 걸음마다 같은 주소에 history.pushState 로 한 칸. 상태에는 Turbo 의 것을 그대로 두고 seonbang 만 더한다.
// Turbo 는 popstate 에 자기 상태가 있으면 그 쪽을 다시 그리므로, 걸음 사이의 뒤로 가기는 Turbo 보다 먼저 단 손
// (seonbang_history)이 받아 이리 넘기고 거기서 멈춘다 — 앉는 중의 화면이 다시 그려지지 않게(앉음이 끊기지 않게).
// 같은 주소의 걸음만 받는다 — 앞의 쪽(들어올 때의 선방)에 쌓인 걸음은 Turbo 가 그 쪽으로 데려간다.
//
// 새로 고침은 늘 ① 방에서 — 걸음을 기억해 되살리지 않는다. 처음 그릴 때 지금 칸의 걸음 값을 「방」으로 바꿔 둔다.
// 앉는 중이었으면 앉음은 그대로 이어지고 보는 자리만 방이다. 새로 고침 앞에 쌓인 같은 주소의 걸음은 그대로 받으므로
// 뒤로 가기는 한 걸음씩 나오다 이 쪽 앞으로 빠져나간다.
//
// 코끼리가 걸어 들어와 앉는 장면은 ③ 에서만 — 처음 ③ 에 들어 걸음이 멎으면 seonbang:within 을 알린다
// (elephant#arrive). ① · ② 에서는 이미 앉아 있다.
import { Controller } from "@hotwired/stimulus"
import { steps } from "controllers/seonbang_history"

const STEPS = [ "room", "near", "within" ]

export default class extends Controller {
  connect() {
    this.url = location.href
    this.handle = state => this.onPop(state)
    this.reset = () => this.show("room", { instant: true })
    steps.handle = this.handle
    document.addEventListener("turbo:before-cache", this.reset)

    // 늘 방에서. 지금 칸에 「방」을 적어 둔다 — 나중에 이리로 돌아올 수 있게.
    history.replaceState({ ...history.state, seonbang: "room" }, "")
    this.show("room", { instant: true })
  }

  disconnect() {
    if (steps.handle === this.handle) steps.handle = null
    document.removeEventListener("turbo:before-cache", this.reset)
    clearTimeout(this.timer)
  }

  // 한 걸음 안으로 — 족자를 누르거나 「든다」.
  forward() {
    const next = STEPS[STEPS.indexOf(this.step) + 1]
    if (!next) return

    history.pushState({ ...history.state, seonbang: next }, "")
    this.show(next)
  }

  // 한 걸음 밖으로 — 「물러난다」 · 「나온다」 · 뒤로 가기는 모두 같은 길이다.
  back() {
    if (this.step !== "room") history.back()
  }

  // 같은 주소의 걸음이면 받고 참을 돌려준다(그러면 Turbo 에 가지 않는다).
  onPop(state) {
    const step = state?.seonbang
    if (!STEPS.includes(step) || location.href !== this.url) return false

    this.show(step)
    return true
  }

  show(step, { instant = false } = {}) {
    const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches
    this.step = step
    this.element.classList.toggle("seonbang--instant", instant || reduced)
    this.element.dataset.step = step
    if (instant || reduced) requestAnimationFrame(() => this.element.classList.remove("seonbang--instant"))

    clearTimeout(this.timer)
    if (step === "within" && !this.within) {
      this.within = true
      this.timer = setTimeout(() => window.dispatchEvent(new CustomEvent("seonbang:within")), instant || reduced ? 0 : entryTime())
    }
  }
}

// 걸음의 시간은 CSS 한 곳(:root 의 --entry-time)에서.
function entryTime() {
  return parseFloat(getComputedStyle(document.documentElement).getPropertyValue("--entry-time")) * 1000 || 0
}

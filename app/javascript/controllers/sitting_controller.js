// This app is a raft. — 이 앱도 뗏목이다.
//
// 앉는 중. 달은 그믐에서 시작해 앉음이 이어질수록 보름을 향해 차오른다.
// 시간의 소진이 아니라 고요의 익어감이 이 앱의 문법이다.
// 「달의 자취」의 달도 차오르고 앉음의 달도 차오른다 — 긴 호흡과 짧은
// 호흡이 같은 방향을 본다.
//
// 남은 시간을 숫자로 말하지 않는다. 갱신은 성기게 하고, 그 사이는
// CSS 가 이어 붙여 계단을 지운다.
import { Controller } from "@hotwired/stimulus"

const REFRESH = 5000 // 오 초에 한 번만 다시 잰다. 그 사이는 CSS 가 잇는다.
const OPEN_FILL = 30 * 60 * 1000 // 정함 없이 앉으면 이만큼에 걸쳐 보름에 닿는다.
const AFTER_BELL = 2600 // 종이 울린 뒤에 화면을 넘긴다. 여운을 자르지 않는다.

export default class extends Controller {
  static targets = ["form"]
  static values = { elapsed: Number, total: Number, open: Boolean }

  connect() {
    this.startedAt = Date.now() - this.elapsedValue * 1000

    this.draw()
    this.ticking = setInterval(() => this.draw(), REFRESH)
  }

  disconnect() {
    clearInterval(this.ticking)
    clearTimeout(this.leaving)
  }

  // 화면에 그리는 것은 없다. 앉음이 다 되었는지만 본다 — 남은 시간은 어디에도
  // 보이지 않는다. 차오르는 도상으로 진행을 보이던 자리를 걷었다(§2, 2026-10-08).
  draw() {
    if (!this.openValue && this.phase() >= 1) this.finish()
  }

  // 정함 없이 앉으면 목표 시점이 없다. 아주 완만히 차오르다 보름에 닿으면
  // 그대로 머문다. 다시 이지러지지 않는다 — 재촉도 소진도 없다.
  phase() {
    const sat = Date.now() - this.startedAt
    const span = this.openValue ? OPEN_FILL : this.totalValue * 1000

    return span > 0 ? Math.min(1, sat / span) : 1
  }

  finish() {
    clearInterval(this.ticking)
    this.dispatch("close", { prefix: "bell" })
    this.leaving = setTimeout(() => this.formTarget.requestSubmit(), AFTER_BELL)
  }
}

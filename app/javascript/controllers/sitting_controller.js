// This app is a raft. — 이 앱도 뗏목이다.
//
// 앉는 중. 남은 시간을 숫자로 말하지 않는다 — 달이 기울 뿐이다.
// 갱신은 성기게 한다. 자주 그리면 초를 세는 느낌이 든다.
import { Controller } from "@hotwired/stimulus"

const REFRESH = 5000 // 5초에 한 번만 다시 그린다.
const AFTER_BELL = 2600 // 종이 울린 뒤에 화면을 넘긴다. 여운을 자르지 않는다.

export default class extends Controller {
  static targets = ["moon", "form"]
  static values = { seconds: Number, open: Boolean, size: Number }

  connect() {
    this.endsAt = Date.now() + this.secondsValue * 1000

    // 종 컨트롤러가 붙은 뒤에 친다.
    setTimeout(() => this.dispatch("open", { prefix: "bell" }), 0)

    if (this.openValue) return // 정함 없이 앉으면 기울 것이 없다.

    this.draw()
    this.ticking = setInterval(() => this.draw(), REFRESH)
  }

  disconnect() {
    clearInterval(this.ticking)
    clearTimeout(this.leaving)
  }

  draw() {
    const left = Math.max(0, this.endsAt - Date.now())
    const total = this.secondsValue * 1000

    this.moonTarget.setAttribute("d", this.path(total ? left / total : 1))

    if (left <= 0) this.finish()
  }

  finish() {
    clearInterval(this.ticking)
    this.dispatch("close", { prefix: "bell" })
    this.leaving = setTimeout(() => this.formTarget.requestSubmit(), AFTER_BELL)
  }

  // app/helpers/moon_helper.rb 의 moon_path_d 와 같은 식이다.
  path(phase) {
    const size = this.sizeValue
    const r = size / 2
    const rx = (r * Math.abs(1 - 2 * phase)).toFixed(3)
    const sweep = phase < 0.5 ? 1 : 0

    return `M ${r} 0 A ${r} ${r} 0 0 1 ${r} ${size} A ${rx} ${r} 0 0 ${sweep} ${r} 0 Z`
  }
}

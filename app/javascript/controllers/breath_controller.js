// This app is a raft. — 이 앱도 뗏목이다.
//
// 셋째 문. 손을 얹고 있는 동안 화면이 밝아졌다 어두워지기를 세 번
// (CSS 의 threshold-breath, 세 번 되풀이). 손을 떼면 처음부터.
// 세 번이 끝나면 어둠이 한지빛으로 밝아지고(threshold-dawn), 그 빛
// 그대로 오늘 화면으로 넘어간다. 몇 번째인지 보여 주지 않고,
// 잘했다는 말도 하지 않는다.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["gate"]

  hold(event) {
    if (this.opening) return
    if (event.target.closest("form, button, a")) return // 「나중에」를 누르는 손은 숨이 아니다.

    event.preventDefault()
    this.element.classList.add("breathing")
  }

  // 떼면 처음부터 — 되풀이 셈도 함께 처음으로 돌아간다.
  // 문이 열리기 시작한 뒤에는 손을 떼도 그대로 열린다.
  release() {
    if (this.opening) return

    this.element.classList.remove("breathing")
  }

  open(event) {
    if (event.target !== this.element) return

    if (event.animationName === "threshold-breath" && this.element.classList.contains("breathing")) {
      this.element.classList.replace("breathing", "opening")
    } else if (event.animationName === "threshold-dawn") {
      this.gateTarget.requestSubmit()
    }
  }

  get opening() { return this.element.classList.contains("opening") }
}

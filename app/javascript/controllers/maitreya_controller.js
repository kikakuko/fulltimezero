// This app is a raft. — 이 앱도 뗏목이다.
//
// 미륵이 올라오는 만큼을 CSS 변수로 넘긴다. 비운 날 아침 첫 화면에서만
// 어제의 자리에서 오늘의 자리로 한 뼘 올라온다 — 그때 흙먼지가 한 번
// 일었다 가라앉는다(CSS). 그 밖에는 그냥 그 자리에 있다.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { rise: Number, before: Number, rising: Boolean }

  connect() {
    const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches

    if (this.risingValue && !reduced) {
      this.element.style.setProperty("--rise", this.beforeValue)
      this.frame = requestAnimationFrame(() => requestAnimationFrame(() => {
        this.element.classList.add("maitreya--moving")
        this.element.style.setProperty("--rise", this.riseValue)
      }))
    } else {
      this.element.style.setProperty("--rise", this.riseValue)
    }
  }

  disconnect() { cancelAnimationFrame(this.frame) }
}

// This app is a raft. — 이 앱도 뗏목이다.
//
// 기다려야 나타나는 것. 서두를 수 없다는 것을 말로 하지 않고, 실제로
// 기다리게 해서 알린다. 세는 것은 보이지 않는다 — 그저 때가 되면 길이 선다.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["reveal"]
  static values = { after: Number }

  connect() {
    this.timer = setTimeout(() => {
      this.revealTargets.forEach(element => {
        element.hidden = false
        element.classList.add("arriving")
      })
    }, this.afterValue)
  }

  disconnect() { clearTimeout(this.timer) }
}

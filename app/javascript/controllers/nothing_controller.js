// This app is a raft. — 이 앱도 뗏목이다.
//
// 무위. 아무것도 주지 않는다.
// 나가는 길은 보이지 않지만, 화면 어디를 눌러도 잠시 나타난다.
import { Controller } from "@hotwired/stimulus"

const SHOWN = 6000

export default class extends Controller {
  static targets = ["leave"]

  connect() {
    // 켜 두었으면 들어갈 때 한 번만. 마침종은 없다 — 무위에는 끝이 없다.
    setTimeout(() => this.dispatch("open", { prefix: "bell" }), 0)
  }

  disconnect() { clearTimeout(this.hiding) }

  reveal() {
    this.leaveTarget.classList.remove("veiled")
    clearTimeout(this.hiding)
    this.hiding = setTimeout(() => this.leaveTarget.classList.add("veiled"), SHOWN)
  }
}

// This app is a raft. — 이 앱도 뗏목이다.
//
// 무위. 아무것도 주지 않는다. 종성은 들어오는 손짓에서 이미 울렸다 —
// 여기에는 소리도, 달도, 진행도 없다.
// 나가는 길은 보이지 않지만, 화면 어디를 눌러도 잠시 나타난다.
import { Controller } from "@hotwired/stimulus"

const SHOWN = 6000

export default class extends Controller {
  static targets = ["leave"]

  disconnect() { clearTimeout(this.hiding) }

  reveal() {
    this.leaveTarget.classList.remove("veiled")
    clearTimeout(this.hiding)
    this.hiding = setTimeout(() => this.leaveTarget.classList.add("veiled"), SHOWN)
  }
}

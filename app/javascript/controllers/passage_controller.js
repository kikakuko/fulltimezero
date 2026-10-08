// This app is a raft. — 이 앱도 뗏목이다.
//
// 둘째 문, 손님의 경우. 적을 것이 없으니 누를 것도 없다. 물음 한 줄이 떠 있고,
// 사천왕이 지켜보는 동안 한 숨 머물다가 그냥 다음 문으로 간다 — 그러면 장막이
// 사천왕을 지나 셋째 문으로 물러난다. 빛이 지나가는 것이지 손이 미는 것이 아니다.
// 셋째 문(breath)과 같은 숨이다. 잘했다는 말도, 손짓도 없다.
import { Controller } from "@hotwired/stimulus"

const DWELL = 4500  // 물음이 떠 있는 동안. 셋째 문과 같다

export default class extends Controller {
  static targets = ["gate"]

  connect() {
    this.timer = setTimeout(() => this.gateTarget.requestSubmit(), DWELL)
  }

  disconnect() { clearTimeout(this.timer) }
}

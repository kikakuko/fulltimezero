// This app is a raft. — 이 앱도 뗏목이다.
//
// 매일 지나는 문. 첫째 문의 빛이 짧게 다가와 한 번 넘치고 가라앉으면
// 문이 옅어지며 그대로 마당이다. 아무 곳이나 누르면 곧장 끝난다.
// 설정에서 끌 수 있다.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  pass() { this.element.remove() }

  // 안쪽 빛의 움직임이 끝난 것은 지나감이 아니다. 문 자신이 옅어진 뒤에만 걷는다.
  settled(event) {
    if (event.target === this.element) this.pass()
  }
}

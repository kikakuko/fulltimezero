// This app is a raft. — 이 앱도 뗏목이다.
//
// 매일 지나는 문. 앱을 열 때 숨 한 번 쉬는 어둠이 지나간다.
// 누르면 곧장 걷힌다. 설정에서 끌 수 있다.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  pass() { this.element.remove() }
}

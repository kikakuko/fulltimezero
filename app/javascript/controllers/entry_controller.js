// This app is a raft. — 이 앱도 뗏목이다.
//
// 전각 화면의 글 자리(compound/_hall_words). 둘을 한다.
//
// 하나 — 출전의 숫자를 넣는다. 출전은 숫자를 담으므로 서버 응답에 두지 않고(화면에
// 숫자가 없다는 자물쇠), 조감도 컨트롤러의 상수(SOURCES)에서 <html lang> 을 보고 꺼낸다.
// 숫자가 없는 출전(미륵당)은 서버가 값으로 싣는다.
//
// 둘 — 이 전각을 떠날 때 조감도가 돌아오는 축을 놓는다. 들어올 때 「든다」가 놓은 것과
// 같은 자리(전각의 가운데 cx · cy)를 turbo:before-render 에서 <html> 에 넣는다. 그 값은
// 다음 방문이 시작될 때 걷힌다 — 조감도 컨트롤러와 같은 손(clearAxis)이다.
import { Controller } from "@hotwired/stimulus"
import { SOURCES, placeAxis, clearAxis } from "controllers/compound_controller"

export default class extends Controller {
  static targets = [ "source" ]
  static values = { key: String, x: Number, y: Number, source: String }

  connect() {
    const locale = document.documentElement.lang
    this.sourceTarget.textContent = this.sourceValue || (SOURCES[locale] || SOURCES.ko)[this.keyValue] || ""

    this.leave = () => placeAxis(this.xValue, this.yValue)
    document.addEventListener("turbo:before-render", this.leave)
    document.addEventListener("turbo:visit", clearAxis)
  }

  disconnect() {
    document.removeEventListener("turbo:before-render", this.leave)
    document.removeEventListener("turbo:visit", clearAxis)
  }
}

// This app is a raft. — 이 앱도 뗏목이다.
// 시간대를 묻지 않고 브라우저에서 추정한다.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    try {
      this.element.value = Intl.DateTimeFormat().resolvedOptions().timeZone
    } catch {
      // 알 수 없으면 서버 기본값을 쓴다.
    }
  }
}

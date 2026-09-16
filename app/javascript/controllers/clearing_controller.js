// This app is a raft. — 이 앱도 뗏목이다.
//
// 「오늘을 비워 둔다」를 누르는 그 손짓 안에서 기기가 짧게 떤다 —
// 미륵이 한 뼘 올라오는 땅의 울림이다. 떨지 말지는 서버의 침묵 게이트가
// 정해서 건네준다. 아이폰에는 진동이 없다. 거두는 손짓에는 떨지 않는다.
import { Controller } from "@hotwired/stimulus"
import { touch } from "lib/haptics"

const RUMBLE = [ 180, 80, 60, 80, 60 ]

export default class extends Controller {
  static values = { vibrate: Boolean, declaring: Boolean }

  declare() {
    if (!this.declaringValue) return

    touch(RUMBLE, this.vibrateValue)
  }
}

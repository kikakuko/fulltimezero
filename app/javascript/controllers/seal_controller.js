// This app is a raft. — 이 앱도 뗏목이다.
//
// 낙관을 찍는 손짓 안에서 기기가 짧게 한 번 떤다 — 도장이 종이에 닿는 느낌이다.
// 떨지 말지는 서버의 침묵 게이트가 정해서 건네준다(비움과 같은 게이트). 아이폰에는 진동이
// 없다. 찍는 모양 자체는 CSS 의 것이다(seal-press · seal-bleed).
import { Controller } from "@hotwired/stimulus"
import { touch } from "lib/haptics"

const TOUCH = [ 40 ]

export default class extends Controller {
  static values = { vibrate: Boolean }

  press() { touch(TOUCH, this.vibrateValue) }
}

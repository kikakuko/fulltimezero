// This app is a raft. — 이 앱도 뗏목이다.
//
// 한 배를 보여 준다. 세지 않는다 — 알은 사람이 누를 때 꿰인다.
//
// 칸은 보간하지 않고 툭 넘어간다(하드 컷). 칸이 바뀌면 안내 한 줄도 함께
// 바뀐다. 움직임을 끈 사람에게는 엎드린 칸으로 멎은 채 보인다.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["figure", "line"]
  static values = { marks: Array, lines: Array, run: Boolean }

  connect() {
    if (this.stilled) return this.rest()
    if (this.runValue) this.bow()
  }

  disconnect() {
    this.timers?.forEach(clearTimeout)
  }

  // 한 배 — 칸마다 제 때에 넘어간다. 마지막 칸이 지나면 첫 칸으로 돌아가 선다.
  bow() {
    this.timers = this.marksValue.map((mark, frame) =>
      setTimeout(() => this.show(frame), mark * 1000)
    )
  }

  show(frame) {
    this.figureTarget.dataset.frame = String(frame)
    if (this.hasLineTarget) this.lineTarget.textContent = this.linesValue[frame]
  }

  // 움직임을 끈 사람 — 가장 깊이 숙인 칸에서 멎는다. 사라지지 않는다.
  rest() {
    this.show(Math.floor(this.marksValue.length / 2))
  }

  get stilled() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}

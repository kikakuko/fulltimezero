// This app is a raft. — 이 앱도 뗏목이다.
//
// 한 배를 보여 준다. 세지 않는다 — 알은 사람이 누를 때 꿰인다.
//
// 칸이 바뀌면 안내 한 줄도 함께 바뀐다. 움직임을 끈 사람에게는 엎드린 칸으로
// 멎은 채 보인다 — 사라지지 않는다.
//
// 자세는 아직 없다. 들어올 것은 부위별 SVG 한 벌과 자세마다의 각도이고, 그때
// 움직임은 보간하고 머묾은 멈춘다 — 각도가 이어지는 동안은 이어지고, 머무는
// 칸에서는 멎는다. 여기서는 칸의 때만 넘긴다(data-frame).
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

// This app is a raft. — 이 앱도 뗏목이다.
//
// 사경. 손가락으로 그은 획을 붓처럼 그린다 — 빨리 그으면 가늘고,
// 천천히 그으면 굵다(perfect-freehand).
//
// 그은 획을 정답과 견주지 않는다. 알아보려 들지도, 점수를 매기지도
// 않는다. 쓰면 그걸로 한 자다. 남기는 것은 그어진 자리 그대로다 —
// 쓰는 자리 안에서의 비율로 적어, 나중에 어떤 크기로도 다시 그릴 수
// 있게 한다.
import { Controller } from "@hotwired/stimulus"
import { getStroke } from "perfect-freehand"

const VIEW = 1000 // 쓰는 자리의 크기 (viewBox)

// 붓의 결. 속도에 따라 굵기가 달라지고 획의 처음과 끝이 가늘어진다.
const BRUSH = {
  size: 46,
  thinning: 0.62,
  smoothing: 0.55,
  streamline: 0.5,
  simulatePressure: true,
  start: { taper: 18, cap: true },
  end: { taper: 30, cap: true }
}

export default class extends Controller {
  static targets = ["surface", "strokes", "field", "offer"]

  connect() {
    this.lines = []
    this.store()
  }

  down(event) {
    event.preventDefault()

    this.current = [this.point(event)]
    this.lines.push(this.current)
    this.path = document.createElementNS("http://www.w3.org/2000/svg", "path")
    this.strokesTarget.append(this.path)
    this.paint()

    // 손가락이 쓰는 자리 밖으로 잠깐 나가도 획이 끊기지 않게 붙잡는다.
    // 붙잡지 못해도 획은 이미 시작되었다.
    try { this.surfaceTarget.setPointerCapture(event.pointerId) } catch {}
  }

  move(event) {
    if (!this.current) return

    // 브라우저가 사이사이 찍어 둔 점까지 받는다. 목록이 비어 오는 곳도 있어
    // 그때는 이 이벤트 하나를 쓴다 — 그러지 않으면 점이 하나도 찍히지 않는다.
    const coalesced = event.getCoalescedEvents?.() || []
    const samples = coalesced.length ? coalesced : [event]
    for (const sample of samples) this.current.push(this.point(sample))
    this.paint()
  }

  up() {
    if (!this.current) return

    this.current = null
    this.store()
  }

  // 지우고 다시 쓴다. 잘 쓰라는 뜻이 아니라, 손이 미끄러졌을 때를 위해서다.
  clear() {
    this.lines = []
    this.strokesTarget.replaceChildren()
    this.store()
  }

  paint() {
    this.path.setAttribute("d", outline(this.current))
  }

  point(event) {
    const box = this.surfaceTarget.getBoundingClientRect()
    const x = (event.clientX - box.left) / box.width
    const y = (event.clientY - box.top) / box.height

    return [round(clamp(x)), round(clamp(y))]
  }

  store() {
    this.fieldTarget.value = JSON.stringify(this.lines)
    this.offerTarget.disabled = this.lines.length === 0
  }
}

function outline(points) {
  const stroke = getStroke(points.map(([x, y]) => [x * VIEW, y * VIEW]), BRUSH)
  return svgPath(stroke)
}

// 외곽선 점들을 부드러운 닫힌 경로로 잇는다.
function svgPath(points) {
  if (points.length < 2) return ""

  const middle = (a, b) => [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2]
  const [first, ...rest] = points
  let d = `M ${first[0].toFixed(1)} ${first[1].toFixed(1)} Q`

  rest.forEach((point, i) => {
    const next = rest[i + 1] || first
    const [mx, my] = middle(point, next)
    d += ` ${point[0].toFixed(1)} ${point[1].toFixed(1)} ${mx.toFixed(1)} ${my.toFixed(1)}`
  })

  return `${d} Z`
}

const clamp = value => Math.min(1, Math.max(0, value))
const round = value => Math.round(value * 10000) / 10000

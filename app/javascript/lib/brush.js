// This app is a raft. — 이 앱도 뗏목이다.
//
// 붓. 쓰는 자리에서도, 탑 위에서도 같은 붓으로 그린다 — 탑에 앉는
// 글씨가 쓸 때와 똑같은 모양이어야 하므로.
//
// 빨리 그으면 가늘고, 천천히 그으면 굵다. 처음과 끝이 가늘어진다
// (perfect-freehand). 획은 쓰는 자리 안에서의 비율 [x, y] 로 받는다.
import { getStroke } from "perfect-freehand"

export const VIEW = 1000 // 쓰는 자리의 크기 (viewBox)

// 붓의 결. 손가락으로 써 보고 정한 값이다 — 함부로 바꾸지 않는다.
export const BRUSH = {
  size: 46,
  thinning: 0.62,
  smoothing: 0.55,
  streamline: 0.5,
  simulatePressure: true,
  start: { taper: 18, cap: true },
  end: { taper: 30, cap: true }
}

// 한 획의 점들을 붓 자국의 외곽선 경로로.
export function outline(points) {
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

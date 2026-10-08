// This app is a raft. — 이 앱도 뗏목이다.
//
// 코끼리의 자리 — 길가의 바위 하나. 코끼리는 길 위를 가지 않는다(§2, 2026-10-08).
// 여기서 하는 일은 둘뿐이다: 숨긴 길과 그 위의 한지빛 덮개에 같은 모양을 주는 것,
// 그리고 선방에 들어설 때 가장자리에서 바위까지 한 번 걸어오게 하는 것.
//
// 걸어오는 것은 자리의 변화가 아니라 문턱이다 — 들어섬이라는 사건에 붙은 움직임이고
// 경과 시간과 무관하다. 바위 앞에 서면 걸음이 그치고 뒤척임이 시작된다.
//
// 빛(--ele) · 뒤척임(--restless) · 길의 옅음(--whiteness)은 서버가 준 값이고 여기서
// 건드리지 않는다. 아홉 자리와 잇지 않는다.
import { Controller } from "@hotwired/stimulus"

// 길의 굽이 — 배경 그림(elephant_field.webp, 좌표는 864 × 1184 의 것) 속 흰 길의
// 굽이마다 한 점. 길의 모양일 뿐이다 — 코끼리는 이 위를 가지 않고, 희어질수록 이
// 길을 한지빛으로 덮는 데에만 쓴다. 이름이 붙지 않는다.
export const ANCHORS = [
  [ 555, 1085 ], [ 175, 905 ], [ 660, 770 ], [ 300, 640 ], [ 640, 555 ],
  [ 325, 470 ], [ 575, 395 ], [ 355, 320 ], [ 464, 150 ]
]
export const VIEW = [ 864, 1184 ]

// 굽이가 아닌 길 점 — 그림의 기하다. 배경을 바꾸면 이것만 손본다.
export const BENDS = {
  7: [ [ 480, 250 ], [ 420, 222 ], [ 450, 195 ], [ 432, 172 ] ]
}

export default class extends Controller {
  static targets = [ "path", "veil", "figure" ]
  static values = { arriving: Boolean }

  connect() {
    const d = catmullRom(road(ANCHORS, BENDS))
    this.pathTarget.setAttribute("d", d)
    this.veilTarget.setAttribute("d", d)

    if (!this.arrivingValue) return

    const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches
    if (reduced) return this.settle()

    // 문턱 — 가장자리에서 바위까지. 다음 틀에서 자리를 풀면 전환이 걸린다.
    this.frame = requestAnimationFrame(() => requestAnimationFrame(() => {
      this.figureTarget.addEventListener("transitionend", () => this.settle(), { once: true })
      this.figureTarget.classList.remove("elephant-place--arriving")
    }))
  }

  disconnect() { cancelAnimationFrame(this.frame) }

  // 바위 앞에 섰다. 걸음을 거두고 뒤척임을 시작한다.
  settle() {
    this.figureTarget.classList.remove("elephant-place--arriving")
    const elephant = this.figureTarget.querySelector(".elephant")
    elephant?.classList.remove("elephant--walking-legs")
    elephant?.classList.add("elephant--restless")
  }
}

// 굽이 사이에 길 점을 끼운 길의 점들.
export function road(anchors, bends) {
  return anchors.flatMap((anchor, index) => [ anchor, ...(bends[index] || []) ])
}

// 점들을 매끄럽게 잇는 길 — Catmull-Rom 을 세제곱 베지어로 옮긴다.
export function catmullRom(points) {
  const at = index => points[Math.min(Math.max(index, 0), points.length - 1)]
  let d = `M ${points[0][0]} ${points[0][1]}`

  for (let i = 0; i < points.length - 1; i++) {
    const [ p0, p1, p2, p3 ] = [ at(i - 1), at(i), at(i + 1), at(i + 2) ]
    const c1 = [ p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6 ]
    const c2 = [ p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6 ]
    d += ` C ${c1[0]} ${c1[1]} ${c2[0]} ${c2[1]} ${p2[0]} ${p2[1]}`
  }

  return d
}

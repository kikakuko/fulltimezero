// This app is a raft. — 이 앱도 뗏목이다.
//
// 코끼리의 길. 서버가 준 흰빛(0 ~ 1)만큼 숨긴 길을 따라가 코끼리를 놓는다.
// 길은 화면에 그리지 않는다 — 시각적 길은 배경 그림 안에 있다.
//
// 자리 · 방향만 계산해 CSS 변수로 넘긴다. 밝기(흰빛)는 서버가 --ele 로 그림에
// 직접 준다. 그림은 부위별 SVG 이고, 걸음은 CSS 가 맡는다.
//
// 아홉 자리와 잇지 않는다. 여기에는 골라 둔 자리에 대한 것이 아무것도 없다.
import { Controller } from "@hotwired/stimulus"

// 길의 앵커 — 배경 그림(elephant_field.webp, 768 × 1052 — 좌표는 864 × 1184 의 것) 속 흰 길의
// 굽이마다 한 점. 아래에서 위로 오른다. 브라우저에서 보며 고칠 수 있게
// 여기 둔다. 정거장 아홉이 이 점 위에 선다.
export const ANCHORS = [
  [ 555, 1085 ], [ 175, 905 ], [ 660, 770 ], [ 300, 640 ], [ 640, 555 ],
  [ 325, 470 ], [ 575, 395 ], [ 355, 320 ], [ 464, 150 ]
]
export const VIEW = [ 864, 1184 ]

// 정거장이 아닌 굽이 — 그림의 기하다. 정거장 아홉은 뜻이 있는 자리고,
// 길 점은 그림 속 길이 굽는 곳이다. 배경을 바꾸면 정거장은 두고 이것만
// 손본다. 열쇠는 그 굽이가 뒤따르는 정거장의 차례(0 부터).
export const BENDS = {
  // 전주일취를 지나 봉우리의 가는 길을 따라 굽는다 — 그림 속 흰 줄의 가운데를 짚었다.
  7: [ [ 480, 250 ], [ 420, 222 ], [ 450, 195 ], [ 432, 172 ] ]
}

// 비스듬함은 접선각을 따르되 이만큼을 넘지 않는다 — 앵커 근처에서 길이
// 거의 곧추서는데, 코끼리가 곧추서면 코끼리가 아니다.
const TILT_MOST = 12

export default class extends Controller {
  static targets = [ "path", "figure" ]
  static values = { whiteness: Number, yesterday: Number, moving: Boolean }

  connect() {
    this.pathTarget.setAttribute("d", catmullRom(road(ANCHORS, BENDS)))

    const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches

    // 흰빛이 바뀐 날에만, 어제의 자리에서 오늘의 자리로 걸어온다.
    if (this.movingValue && !reduced) {
      this.place(this.yesterdayValue)
      this.frame = requestAnimationFrame(() => requestAnimationFrame(() => {
        this.figureTarget.classList.add("elephant-place--walking")
        this.place(this.whitenessValue)
      }))
      // 아홉째에 닿는 날 — 길을 다 올라온 뒤에 선다.
      if (this.figureTarget.dataset.halt === "true") {
        this.figureTarget.addEventListener("transitionend", () => this.halt(), { once: true })
      }
    } else {
      this.place(this.whitenessValue)
    }
  }

  disconnect() { cancelAnimationFrame(this.frame) }

  halt() {
    this.figureTarget.querySelector(".elephant")?.classList.remove("elephant--walking-legs")
  }

  // 길 위의 한 점과 그곳의 접선. 그림은 왼쪽을 보므로 오른쪽으로 갈 때는 뒤집는다.
  place(whiteness) {
    const path = this.pathTarget
    const total = path.getTotalLength()
    const at = Math.min(Math.max(whiteness, 0), 1) * total
    const here = path.getPointAtLength(at)
    const ahead = path.getPointAtLength(Math.min(at + 2, total))
    const behind = path.getPointAtLength(Math.max(at - 2, 0))
    const dx = ahead.x - behind.x
    const dy = ahead.y - behind.y

    const facingLeft = dx < 0
    const heading = Math.atan2(dy, dx) * 180 / Math.PI
    // 왼쪽을 보는 그림의 앞은 백팔십 도다. 뒤집으면 앞이 영 도가 된다.
    const tilt = clamp(facingLeft ? heading - 180 : heading, -TILT_MOST, TILT_MOST)

    const style = this.figureTarget.style
    style.setProperty("--x", `${(here.x / VIEW[0]) * 100}%`)
    style.setProperty("--y", `${(here.y / VIEW[1]) * 100}%`)
    style.setProperty("--angle", `${tilt}deg`)
    style.setProperty("--flip", facingLeft ? 1 : -1)
  }
}

// 정거장 사이에 굽이를 끼운 길의 점들.
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

function clamp(value, low, high) {
  return Math.min(Math.max(value, low), high)
}

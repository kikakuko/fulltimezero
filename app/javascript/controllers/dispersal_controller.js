// This app is a raft. — 이 앱도 뗏목이다.
//
// 무위에 들면 코끼리가 천천히 흩어져 사라진다. 잠깐 오색이 번지고 이내 어둠.
// 누구든 매번 본다 — 흰빛을 읽지 않고, 본 적이 있는지 적어 두지 않는다.
import { Controller } from "@hotwired/stimulus"

const STILL = 1500     // 흩어지기 전, 코끼리가 그대로 서 있는 동안
const SPREAD = 5000    // 첫 조각과 마지막 조각이 떠나는 사이
const DRIFT = 4500     // 조각 하나가 흩어져 사라지는 동안 — 다 합쳐 열한 초
const COLUMNS = 25  // 조각 한 칸이 온 화소가 되게 — 틈이 줄로 보이지 않는다
const ROWS = 15

export default class extends Controller {
  static targets = ["figure", "image", "bloom"]

  connect() {
    if (matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.element.classList.add("void__scene--still")
      return
    }

    const image = this.imageTarget
    // 서 있는 동안은 그림 한 장 그대로 — 조각의 이음매가 보이지 않는다.
    const begin = () => { this.timer = setTimeout(() => this.scatter(), STILL) }
    image.complete ? begin() : image.addEventListener("load", begin, { once: true })
  }

  disconnect() { clearTimeout(this.timer) }

  scatter() {
    const figure = this.figureTarget
    const width = figure.offsetWidth
    const height = figure.offsetHeight
    const src = this.imageTarget.currentSrc || this.imageTarget.src
    const w = width / COLUMNS
    const h = height / ROWS

    const pieces = document.createDocumentFragment()
    for (let row = 0; row < ROWS; row++) {
      for (let column = 0; column < COLUMNS; column++) {
        const piece = document.createElement("span")
        piece.className = "void__piece"
        // 코끼리는 왼쪽을 본다. 꼬리 쪽에서 코 쪽으로, 위에서 아래로 — 조금씩 어긋나게.
        const order = (1 - column / COLUMNS) * 0.7 + (row / ROWS) * 0.3
        const delay = (order * 0.8 + Math.random() * 0.2) * SPREAD
        const angle = -Math.PI / 2 + (Math.random() - 0.5) * Math.PI * 1.4
        const reach = 30 + Math.random() * 90

        Object.assign(piece.style, {
          left: `${column * w}px`, top: `${row * h}px`, width: `${w}px`, height: `${h}px`,
          backgroundImage: `url("${src}")`,
          backgroundSize: `${width}px ${height}px`,
          backgroundPosition: `${-column * w}px ${-row * h}px`
        })
        piece.style.setProperty("--dx", `${Math.cos(angle) * reach}px`)
        piece.style.setProperty("--dy", `${Math.sin(angle) * reach}px`)
        piece.style.setProperty("--turn", `${(Math.random() - 0.5) * 90}deg`)
        piece.style.animationDelay = `${delay}ms`
        piece.style.animationDuration = `${DRIFT}ms`
        pieces.appendChild(piece)
      }
    }

    figure.appendChild(pieces)
    this.element.classList.add("void__scene--scattering")
    // 마지막 조각들이 옅어질 즈음 오색이 번진다.
    this.bloomTarget.style.animationDelay = `${SPREAD + DRIFT * 0.1}ms`
  }
}

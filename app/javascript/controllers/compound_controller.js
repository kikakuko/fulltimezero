// This app is a raft. — 이 앱도 뗏목이다.
//
// 전각에 드는 흐름. 전각을 누르면 화면을 바꾸지 않고 카드가 아래에서
// 올라와 무엇이 있는 곳인지 말한다 — 이름 · 한 줄 · 「든다」. 「든다」를 누르면
// 조감도가 그 전각을 향해 커지며 사라지고, 그 방이 같은 시간에 겹쳐 들어온다
// (View Transition — Turbo 가 meta view-transition 을 보고 한다. 값은 CSS 의
// --entry-time · --entry-scale). 여기서 하는 일은 축을 놓는 것뿐이다: 전각의
// 가운데(cx · cy)를 turbo:before-render 에서 <html> 에 넣는다. 옛 화면의 스냅숏은
// 이미 담긴 뒤이고 새 화면은 아직 그려지기 전이라, 전환의 의사 요소가 그 값으로 선다.
// 그 값은 다음 방문이 시작될 때(turbo:visit) 걷힌다 — 전환이 도는 동안 걷으면 축이 튄다.
//
// 지원하지 않는 브라우저에서는 방문 앞에 조감도만 커진다(같은 값, 같은 시간).
// 움직임을 줄인 화면에서는 둘 다 건너뛰고 곧장 든다 — 전환은 Turbo 가 스스로 끈다.
//
// 카드를 열고 읽는 것은 구조이지 움직임이 아니다 — 움직임을 줄인 화면에서도
// 카드는 그대로 뜬다.
import { Controller } from "@hotwired/stimulus"

// 출전 — 숫자를 담고 있어 로케일 파일에 둘 수 없다(카피 어디에도 숫자가 없어야
// 화면에 숫자가 없다는 말이 우연이 아니게 된다 — spirit_test). 전각 화면의 글 자리
// (entry 컨트롤러)가 <html lang> 을 보고 여기서 꺼내 넣는다.
// 이 넷은 숫자를 담는다. 다섯째(날들의 전각)는 숫자가 없어 로케일에 그대로
// 있고 서버가 싣는다 — 그 이름을 여기 적지 않는 것은 숫자를 가진 이 파일과 한
// 자리에 있으면 안 되는 자물쇠가 있기 때문이다.
export const SOURCES = {
  ko: {
    sitting: "『법구경』 35",
    copying: "『금강경』 제12 존중정교분",
    lecture: "『법구경』 204",
    gate: "『앙굴리말라경』 MN 86"
  },
  en: {
    sitting: "Dhammapada 35",
    copying: "Diamond Sūtra, ch. 12",
    lecture: "Dhammapada 204",
    gate: "Aṅgulimāla Sutta, MN 86"
  }
}

// 확대의 축 — 전각의 가운데를 조감도에 대한 백분율로 <html> 에 둔다. 전환의 의사
// 요소(::view-transition-old(compound) · -new(compound))가 거기서 커지고 돌아온다.
export function placeAxis(cx, cy) {
  const root = document.documentElement.style
  root.setProperty("--zoom-x", `${cx}%`)
  root.setProperty("--zoom-y", `${cy}%`)
}

// 다음 방문이 시작될 때 걷는다. <html> 은 Turbo 가 갈아 끼우지 않으므로 누군가 걷어야 한다.
export function clearAxis() {
  const root = document.documentElement.style
  root.removeProperty("--zoom-x")
  root.removeProperty("--zoom-y")
}

// CSS 의 시간을 읽는다 — 값은 한 곳(:root)에만 있다.
export function entryTime() {
  return parseFloat(getComputedStyle(document.documentElement).getPropertyValue("--entry-time")) * 1000 || 0
}

export default class extends Controller {
  static targets = [ "scene", "halo", "veil", "backdrop", "card", "cardName", "cardLine", "cardEnter" ]

  connect() {
    document.addEventListener("turbo:visit", clearAxis)
  }

  disconnect() {
    document.removeEventListener("turbo:visit", clearAxis)
    if (this.axis) document.removeEventListener("turbo:before-render", this.axis)
  }

  // 전각을 누르면 카드가 올라온다. 화면은 바뀌지 않는다.
  open(event) {
    event.preventDefault()

    const { name, line, enter, cx, cy, picture } = event.params

    this.opened = { href: event.currentTarget.getAttribute("href"), cx, cy }
    this.entering = false

    this.cardNameTarget.textContent = name
    this.cardLineTarget.textContent = line
    this.cardEnterTarget.textContent = enter

    this.haloTarget.hidden = false
    this.haloTarget.style.left = `${cx}%`
    this.haloTarget.style.top = `${cy}%`

    this.cardTarget.setAttribute("aria-hidden", "false")
    this.element.classList.add("compound--card-open")

    // 방을 미리 받아 둔다 — 「든다」를 누를 즈음엔 이미 와 있어 끊기지 않는다.
    // 느려도 장면을 늘리지 않는다. 받아 오는 동안 그냥 기다리지 않을 뿐이다.
    // 전각 그림이 있으면 그 한 장도 — 교차 페이드가 빈 그림으로 피지 않게.
    this.prefetch(this.opened.href, picture)
  }

  close() {
    this.element.classList.remove("compound--card-open")
    this.cardTarget.setAttribute("aria-hidden", "true")
    this.haloTarget.hidden = true
    this.opened = null
  }

  prefetch(href, picture) {
    if (this.prefetched === href) return

    this.prefetched = href
    fetch(href, { headers: { Accept: "text/html" }, credentials: "same-origin" }).catch(() => {})
    if (picture) new Image().src = picture
  }

  // 「든다」 — 한 번만 든다. 조감도가 전각을 향해 커지며 사라지고 그 방이 겹쳐 들어온다.
  async enter() {
    if (!this.opened || this.entering) return

    const { href, cx, cy } = this.opened
    this.entering = true

    if (matchMedia("(prefers-reduced-motion: reduce)").matches) return this.go(href)

    this.close()

    if (document.startViewTransition) {
      // 전환은 Turbo 가 한다. 축만 놓는다 — 스냅숏이 담긴 뒤, 새 화면이 그려지기 전에.
      this.axis = () => { placeAxis(cx, cy); this.axis = null }
      document.addEventListener("turbo:before-render", this.axis, { once: true })
      return this.go(href)
    }

    // 지원하지 않는 브라우저 — 방문 앞에 조감도만 커지며 한지빛으로 옅어진다. 손은 받지 않는다.
    this.sceneTarget.style.setProperty("--zoom-x", `${cx}%`)
    this.sceneTarget.style.setProperty("--zoom-y", `${cy}%`)
    this.element.classList.add("compound--zooming")

    await settle(this.sceneTarget, entryTime())
    this.go(href)
  }

  go(href) {
    window.Turbo ? window.Turbo.visit(href) : (window.location.href = href)
  }
}

function settle(element, ms) {
  return new Promise(resolve => {
    const done = () => { clearTimeout(timer); element.removeEventListener("transitionend", ended); resolve() }
    const ended = event => { if (event.target === element && event.propertyName === "transform") done() }
    const timer = setTimeout(done, ms + 200)
    element.addEventListener("transitionend", ended)
  })
}

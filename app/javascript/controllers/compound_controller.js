// This app is a raft. — 이 앱도 뗏목이다.
//
// 전각에 드는 흐름. 전각을 누르면 화면을 바꾸지 않고 카드가 아래에서
// 올라와 무엇이 있는 곳인지 말한다. 「든다」를 누르면 조감도가 그 전각을
// 향해 커지며 한지빛으로 옅어지고, 그 방으로 넘어간다.
//
// 카드를 열고 읽는 것은 구조이지 움직임이 아니다 — 움직임을 줄인 화면에서도
// 카드는 그대로 뜨고, 확대 · 축소만 건너뛴다.
import { Controller } from "@hotwired/stimulus"

const ZOOM = 700   // 조감도가 커지며 옅어지는 동안
const LABEL = 250  // 가운데 이름이 뜬 채로 머무는 동안

// 출전 — 카드에만 뜨는 인용 표시다. 숫자를 담고 있어 로케일 파일에 둘 수
// 없다(카피 어디에도 숫자가 없어야 화면에 숫자가 없다는 말이 우연이 아니게
// 된다 — spirit_test). 언어는 <html lang> 에서 읽는다.
// 이 넷은 숫자를 담는다. 다섯째(날들의 전각)는 숫자가 없어 로케일에 그대로
// 있고 event.params.source 로 온다 — 그 이름을 여기 적지 않는 것은 숫자를
// 가진 이 파일과 한 자리에 있으면 안 되는 자물쇠가 있기 때문이다.
const SOURCES = {
  ko: {
    sitting: "『대승장엄경론』 제14장 · 구주심",
    copying: "『금강경』 제12 존중정교분",
    lecture: "『법구경』 204",
    gate: "『앙굴리말라경』 MN 86"
  },
  en: {
    sitting: "Mahāyānasūtrālaṃkāra, ch. 14",
    copying: "Diamond Sūtra, ch. 12",
    lecture: "Dhammapada 204",
    gate: "Aṅgulimāla Sutta, MN 86"
  }
}

export default class extends Controller {
  static targets = [
    "scene", "halo", "veil", "zoomLabel", "backdrop", "card",
    "cardName", "cardHan", "cardLine", "cardVerse", "cardSource", "cardEnter"
  ]

  // 전각을 누르면 카드가 올라온다. 화면은 바뀌지 않는다.
  open(event) {
    event.preventDefault()

    const { key, name, han, line, verse, source, enter, cx, cy } = event.params
    const locale = document.documentElement.lang
    // 넷은 여기서, 나머지 하나는 로케일에서 이미 온 채로 있다.
    const cited = source || (SOURCES[locale] || SOURCES.ko)[key] || ""

    this.opened = { href: event.currentTarget.getAttribute("href"), cx, cy, name }

    this.cardNameTarget.textContent = name
    this.cardHanTarget.textContent = han
    this.cardLineTarget.textContent = line
    this.cardVerseTarget.textContent = verse
    this.cardSourceTarget.textContent = cited
    this.cardEnterTarget.textContent = enter

    this.haloTarget.hidden = false
    this.haloTarget.style.left = `${cx}%`
    this.haloTarget.style.top = `${cy}%`

    this.cardTarget.setAttribute("aria-hidden", "false")
    this.element.classList.add("compound--card-open")

    // 방을 미리 받아 둔다 — 「든다」를 누를 즈음엔 이미 와 있어 끊기지 않는다.
    // 느려도 장면을 늘리지 않는다. 받아 오는 동안 그냥 기다리지 않을 뿐이다.
    this.prefetch(this.opened.href)
  }

  close() {
    this.element.classList.remove("compound--card-open")
    this.cardTarget.setAttribute("aria-hidden", "true")
    this.haloTarget.hidden = true
    this.opened = null
  }

  prefetch(href) {
    if (this.prefetched === href) return

    this.prefetched = href
    fetch(href, { headers: { Accept: "text/html" }, credentials: "same-origin" }).catch(() => {})
  }

  // 「든다」 — 조감도가 전각을 향해 커지며 한지빛으로 옅어진 뒤 그 방으로.
  async enter() {
    if (!this.opened) return

    const { href, cx, cy, name } = this.opened

    if (matchMedia("(prefers-reduced-motion: reduce)").matches) return this.go(href)

    this.close()
    this.sceneTarget.style.setProperty("--zoom-x", `${cx}%`)
    this.sceneTarget.style.setProperty("--zoom-y", `${cy}%`)
    this.zoomLabelTarget.textContent = name
    this.element.classList.add("compound--zooming")

    await settle(this.sceneTarget, ZOOM)
    await wait(LABEL)
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

function wait(ms) {
  return new Promise(resolve => setTimeout(resolve, ms))
}

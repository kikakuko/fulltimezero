// This app is a raft. — 이 앱도 뗏목이다.
//
// 사경. 손가락으로 그은 획을 붓처럼 그린다(lib/brush).
//
// 그은 획을 정답과 견주지 않는다. 알아보려 들지도, 점수를 매기지도
// 않는다. 쓰면 그걸로 한 자다. 남기는 것은 그어진 자리 그대로다 —
// 쓰는 자리 안에서의 비율로 적어, 나중에 어떤 크기로도 다시 그릴 수
// 있게 한다.
//
// 올리면 방금 쓴 글씨가 탑의 제 자리로 날아가 앉는다(lib/pagoda_scene).
import { Controller } from "@hotwired/stimulus"
import { outline } from "lib/brush"
import { touch } from "lib/haptics"
import { playScene } from "lib/pagoda_scene"

const LANDING = 30 // 앉는 순간의 짧은 떨림

export default class extends Controller {
  static targets = ["surface", "strokes", "field", "offer", "art"]
  static values = { vibrate: Boolean, pagoda: String }

  connect() {
    this.lines = []
    this.store()
  }

  down(event) {
    event.preventDefault()

    const first = this.point(event)
    if (!first) return

    this.current = [first]
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
    for (const sample of samples) {
      const point = this.point(sample)
      if (point) this.current.push(point)
    }
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

  // 올린다. 받아들여지면 글씨가 탑으로 가는 장면을 틀고,
  // 장면이 끝나면 「오늘 몫은 끝났다」로 간다. 무엇이 어긋나면 장면 없이
  // 평소대로 보낸다 — 서버가 까닭을 한 줄로 말해 준다.
  async offer(event) {
    event.preventDefault()
    if (this.sending) return
    this.sending = true

    const form = event.target
    const response = await fetch(form.action, {
      method: "POST", body: new FormData(form), headers: { Accept: "application/json" }, credentials: "same-origin"
    }).catch(() => null)

    if (response?.status !== 201) return HTMLFormElement.prototype.submit.call(form)

    const { scene } = await response.json()
    await playScene({
      scene,
      art: this.hasArtTarget ? this.artTarget.content.firstElementChild.cloneNode(true) : null,
      flier: { rect: this.surfaceTarget.getBoundingClientRect(), content: this.strokesTarget.cloneNode(true) },
      label: this.pagodaValue,
      reduced: matchMedia("(prefers-reduced-motion: reduce)").matches,
      onLand: () => touch(LANDING, this.vibrateValue)
    })

    window.Turbo ? window.Turbo.visit(location.href, { action: "replace" }) : location.reload()
  }

  paint() {
    this.path.setAttribute("d", outline(this.current))
  }

  // 쓰는 자리 안에서의 비율. 어떤 까닭으로든 숫자가 아니면 점을 찍지 않는다.
  point(event) {
    const box = this.surfaceTarget.getBoundingClientRect()
    const x = (event.clientX - box.left) / box.width
    const y = (event.clientY - box.top) / box.height

    return Number.isFinite(x) && Number.isFinite(y) ? [round(clamp(x)), round(clamp(y))] : null
  }

  store() {
    this.fieldTarget.value = JSON.stringify(this.lines)
    this.offerTarget.disabled = this.lines.length === 0
  }
}

const clamp = value => Math.min(1, Math.max(0, value))
const round = value => Math.round(value * 10000) / 10000

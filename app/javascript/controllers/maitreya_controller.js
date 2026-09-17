// This app is a raft. — 이 앱도 뗏목이다.
//
// 미륵이 솟는 장면. 「오늘을 비워 둔다」를 누르는 그 순간 마당이 물러나고
// 땅과 미륵만 남는다. 땅이 울리고, 미륵이 한 뼘 솟고, 넉 초에 전부 멎는다 —
// 요란함 뒤의 고요가 요란함을 크게 만든다. 흔들림 · 먼지 · 금빛의 결은 CSS 에 있다.
//
// 선언은 누르는 순간 바로 서버에 보낸다. 장면을 보다가 앱을 닫아도 비움은
// 남는다. 아무 곳이나 누르면 곧장 끝나고 마당으로 돌아간다.
// 장면은 하루 한 번이다 — 그 판단은 서버가 하고, 여기서는 받은 장면만 튼다.
// 얼마나 올라왔는지는 비율로만 받는다. 몇 번째인지는 모른다.
import { Controller } from "@hotwired/stimulus"

const FADE = 300     // 마당이 물러나는 동안
const SCENE = 4000   // 땅이 울리고 멎기까지

export default class extends Controller {
  static targets = ["scene"]

  rise(event) {
    if (!this.hasSceneTargetOnce()) return

    event.preventDefault()
    const form = event.target.closest("form")
    this.saved = fetch(form.action, {
      method: "POST", body: new FormData(form), credentials: "same-origin", headers: { Accept: "text/html" }
    }).catch(() => {})

    const scene = this.sceneTarget.content.firstElementChild.cloneNode(true)
    this.sceneTarget.remove()
    document.body.appendChild(scene)
    this.scene = scene

    scene.addEventListener("click", event => {
      event.preventDefault()
      this.finish()
    })

    requestAnimationFrame(() => requestAnimationFrame(() => scene.classList.add("maitreya-scene--playing")))
    this.timer = setTimeout(() => this.settle(), FADE + SCENE)
  }

  // 장면이 두 번 틀리지 않게 한다 — 템플릿은 한 번 쓰고 걷는다.
  hasSceneTargetOnce() {
    return this.hasSceneTarget && !this.scene
  }

  // 전부 멎었다. 한 줄이 있으면 그 자리에 두고 기다리고, 없으면 마당으로.
  settle() {
    this.scene.classList.add("maitreya-scene--still")
    if (!this.scene.querySelector(".maitreya-scene__line")) this.finish()
  }

  async finish() {
    if (this.finishing) return

    this.finishing = true
    clearTimeout(this.timer)
    await this.saved
    this.scene.remove()
    window.Turbo ? window.Turbo.visit(window.location.pathname, { action: "replace" }) : window.location.reload()
  }

  disconnect() { clearTimeout(this.timer) }
}

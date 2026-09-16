// This app is a raft. — 이 앱도 뗏목이다.
//
// 탑을 보는 자리. 장면이 아니라 가만히 선 탑이다 — 날아오는 것도,
// 다가가는 것도, 흔들리는 것도 없다. 그린 것은 쓴 자리뿐이다.
import { Controller } from "@hotwired/stimulus"
import { buildPagoda } from "lib/pagoda_scene"

export default class extends Controller {
  static targets = ["art"]
  static values = { scene: Object, label: String }

  connect() {
    const art = this.hasArtTarget ? this.artTarget.content.firstElementChild.cloneNode(true) : null

    this.element.append(buildPagoda({ scene: this.sceneValue, art, label: this.labelValue }))
  }
}

// This app is a raft. — 이 앱도 뗏목이다.
//
// 종성. 이 앱에서 소리를 내는 유일한 파일이다 — 다른 어디에도 오디오를
// 다루는 코드가 있어서는 안 된다(test/integration/silence_test.rb).
// 울릴지 말지는 서버의 침묵 게이트가 이미 정해서 건네준다.
//
// 파일이 먼저다. app/assets/sounds/ 에 종이 있으면 그것으로 울고,
// 없으면 아래에서 합성한다. 합성음의 기준은 "전자 알림음"이 아니라
// "종의 여운"이다 — 싱잉볼은 배음이 정수배가 아니고, 여운이 길다.
// 여운이 뚝 끊기면 실패다.
import { Controller } from "@hotwired/stimulus"

const BASE = 196 // 기본음
const TAIL = 24 // 여운. 스물넉 초. 스무 초 아래로 내리지 않는다.

// 싱잉볼의 비조화 배음. 정수배가 아니어서 종처럼 들린다.
const PARTIALS = [
  { ratio: 1.0, gain: 1.0, tail: 1.0 },
  { ratio: 2.7, gain: 0.42, tail: 0.55 },
  { ratio: 5.4, gain: 0.18, tail: 0.3 },
  { ratio: 8.93, gain: 0.07, tail: 0.16 }
]

export default class extends Controller {
  static values = { enabled: Boolean, startUrl: String, endUrl: String }

  opening() { this.ring(this.startUrlValue) }
  closing() { this.ring(this.endUrlValue) }

  ring(url) {
    if (!this.enabledValue) return // 게이트가 막았거나 사용자가 끈 자리다.

    if (url) this.playFile(url)
    else this.synthesize()
  }

  playFile(url) {
    const audio = new Audio(url)
    audio.play().catch(() => {}) // 브라우저가 막으면 그냥 조용한 것이다.
  }

  synthesize() {
    const ctx = this.context
    if (!ctx) return

    const at = ctx.currentTime + 0.02
    const out = ctx.createGain()
    out.gain.value = 0.22
    out.connect(ctx.destination)

    for (const partial of PARTIALS) {
      // 아주 살짝 어긋난 두 벌이 겹치며 울림(맥놀이)을 만든다.
      for (const detune of [-0.5, 0.5]) {
        this.partial(ctx, out, partial, detune, at)
      }
    }
  }

  partial(ctx, out, partial, detune, at) {
    const tail = TAIL * partial.tail
    const osc = ctx.createOscillator()
    osc.type = "sine"
    osc.frequency.value = BASE * partial.ratio + detune

    const gain = ctx.createGain()
    gain.gain.setValueAtTime(0.0001, at)
    gain.gain.exponentialRampToValueAtTime(partial.gain, at + 0.006)
    gain.gain.exponentialRampToValueAtTime(0.0001, at + tail)
    gain.gain.linearRampToValueAtTime(0, at + tail + 0.8) // 뚝 끊지 않는다.

    osc.connect(gain).connect(out)
    osc.start(at)
    osc.stop(at + tail + 1)
  }

  get context() {
    if (this.ctx) return this.ctx

    const Sound = window.AudioContext || window.webkitAudioContext
    if (!Sound) return null

    this.ctx = new Sound()
    if (this.ctx.state === "suspended") this.ctx.resume().catch(() => {})

    return this.ctx
  }
}

// This app is a raft. — 이 앱도 뗏목이다.
//
// 종성. 이 앱에서 소리를 내는 유일한 파일이다 — 다른 어디에도 오디오를
// 다루는 코드가 있어서는 안 된다(test/integration/silence_test.rb).
// 울릴지 말지는 서버의 침묵 게이트가 이미 정해서 건네준다.
//
// 죽비가 먼저, 입정이 다음이다.
//
// 브라우저는 사용자의 손짓 없이 시작된 소리를 막는다. 그래서 오디오
// 컨텍스트는 「앉는다」를 누르는 그 손짓 안에서 깨운다. 다만 소리를
// 그 자리에서 내지는 않는다 — 탭과 동시에 울리는 종은 의례가 아니라
// 버튼 효과음이 된다.
//
// 대신 손짓 안에서 깨우고 잠깐 뒤에 치도록 예약한다. 그동안 화면이
// 어두워지고, 어둠이 완성될 무렵 종이 울리고, 여운이 잦아드는 그
// 시간이 입정이 된다. 예약은 깨어 있는 컨텍스트의 시간선 위에서
// 이루어지므로 정확하다.
//
// 깨어난 컨텍스트는 문서 전체가 함께 쓴다. Turbo 는 문서를 갈아치우지
// 않으므로 앉기 화면에서 깨운 것이 앉는 자리까지 살아서 따라온다 —
// 마침종이 지체 없이 울리는 이유다.
import { Controller } from "@hotwired/stimulus"

// 탭에서 종까지. 어둠이 내려앉는 동안이다.
const ENTERING = 0.9

const BASE = 196 // 기본음
const TAIL = 24 // 여운. 스물넉 초. 스무 초 아래로 내리지 않는다.

// 싱잉볼은 배음이 정수배가 아니다. 그래서 알림음이 아니라 종으로 들린다.
const PARTIALS = [
  { ratio: 1.0, gain: 1.0, tail: 1.0 },
  { ratio: 2.7, gain: 0.42, tail: 0.55 },
  { ratio: 5.4, gain: 0.18, tail: 0.3 },
  { ratio: 8.93, gain: 0.07, tail: 0.16 }
]

// 문서 하나에 컨텍스트 하나. Turbo 전환을 건너 살아남는다.
let shared = null

function wake() {
  const Sound = window.AudioContext || window.webkitAudioContext
  if (!Sound) return null

  if (!shared) shared = new Sound()
  if (shared.state !== "running") shared.resume().catch(() => {})

  return shared
}

export default class extends Controller {
  static targets = ["switch"]
  static values = { enabled: Boolean, startUrl: String, endUrl: String, measure: Boolean }

  // 「앉는다」를 누르는 그 손짓 안에서 불린다. 컨텍스트를 여기서 깨우고,
  // 종은 어둠이 내려앉을 즈음에 울리도록 예약해 둔다.
  open(event) {
    if (!this.wanted()) return

    this.at = event?.timeStamp
    this.ring(this.startUrlValue, ENTERING)
  }

  // 앉음의 끝을 알리는 것은 종의 본업이다. 여기서는 지체하지 않는다.
  closing() {
    if (!this.wanted()) return

    this.at = null
    this.ring(this.endUrlValue, 0)
  }

  // 게이트가 열어 두었고, 사용자가 종을 켜 두었을 때만.
  wanted() {
    if (!this.enabledValue) return false

    return this.hasSwitchTarget ? this.switchTarget.checked : true
  }

  ring(url, after) {
    const ctx = wake()
    if (!ctx) return

    if (ctx.state === "running") return this.sound(ctx, url, after)

    // 아직 깨지 않았으면 깬 뒤에 친다. 얼어붙은 시간선에 예약해 두었다가
    // 한참 뒤에 놀래키지 않는다. 끝내 깨지 못하면 그냥 조용한 것이다.
    ctx.resume().then(() => this.sound(ctx, url, after)).catch(() => {})
  }

  sound(ctx, url, after) {
    if (url) this.playFile(url, after)
    else this.synthesize(ctx, after)

    if (this.measureValue && this.at) {
      const waited = Math.round(performance.now() - this.at + after * 1000)
      console.debug(`종성: 탭에서 ${waited}ms 뒤`)
    }
  }

  playFile(url, after) {
    const audio = new Audio(url)
    const strike = () => audio.play().catch(() => {}) // 막히면 그냥 조용한 것이다.

    after > 0 ? setTimeout(strike, after * 1000) : strike()
  }

  synthesize(ctx, after) {
    const at = ctx.currentTime + 0.02 + after
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
}

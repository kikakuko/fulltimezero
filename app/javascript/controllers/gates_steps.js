// This app is a raft. — 이 앱도 뗏목이다.
//
// 첫 화면의 걸음(docs/M-landing-design.md) — 원경 → 일주문 B → D3c → 천왕문 왼쪽 벽 → 오른쪽 벽 → 불이문.
// 그림은 걸음마다 한 장(.gates__shot)이고, 남겨 두는 틀(#gates) 안에 겹쳐 서 있다. 지금 걸음의 그림만 보이고(is-here),
// 다음 걸음의 그림은 걸음이 멎은 뒤 미리 받는다(is-near — 보이지 않는 채로 그려 두어 브라우저가 받는다). 데이터를
// 아끼는 기기(saveData)면 미리 받지 않고 그 걸음에 들어설 때 받는다. 걸음 안에서는 그림이 움직이지 않는다 — 옮아감은
// 걸음 사이의 겹침(불투명도)과 ① → ② 의 다가감(확대) 하나뿐이고, 값과 시간은 CSS 에 있다.
// 이 손은 서버에 묻지 않는다. 걸음을 어디에도 적지 않는다.
export const STEPS = [ "far", "gate", "within", "wall-left", "wall-right", "burimun" ]
const SHOT = { far: "far", approach: "far", gate: "gate-b", within: "gate-d", "wall-left": "wall-left",
               "wall-right": "wall-right", burimun: "burimun" }

export const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches
const saveData = () => navigator.connection?.saveData === true

// 걸음의 시간은 CSS 한 곳(:root 의 --entry-time)에서.
export function entryTime() {
  return reduced() ? 0 : parseFloat(getComputedStyle(document.documentElement).getPropertyValue("--entry-time")) * 1000 || 0
}

const gates = () => document.getElementById("gates")
const shot = name => gates()?.querySelector(`.gates__shot--${name}`)

// 한 걸음으로. 다음 그림을 먼저 그려 두고(is-near) 한 틀 뒤에 보이게 해야 겹침이 옅어짐으로 옮아간다.
export function showStep(step, { instant = false } = {}) {
  const frame = gates()
  if (!frame) return
  const target = shot(SHOT[step])
  frame.classList.toggle("gates--instant", instant || reduced())
  target?.classList.add("is-near")
  if (target) target.getBoundingClientRect()
  frame.dataset.step = step
  document.querySelectorAll(".threshold").forEach(el => { el.dataset.step = step })
  // 떠나는 그림은 다 덮일 때까지 그대로 서 있다(is-leaving) — 둘이 반씩 옅어지면 한지가 비쳐 그림이 씻긴다.
  // 들어오는 그림이 늘 위에 선다(뒤로 가기도 같다).
  frame.querySelectorAll(".gates__shot.is-here").forEach(el => {
    if (el === target) return
    el.classList.remove("is-here")
    el.classList.add("is-leaving")
    clearTimeout(el.leaveTimer)
    el.leaveTimer = setTimeout(() => el.classList.remove("is-leaving"), instant || reduced() ? 0 : entryTime())
  })
  target?.classList.remove("is-leaving")
  target?.classList.add("is-here")
  if (instant || reduced()) requestAnimationFrame(() => frame.classList.remove("gates--instant"))
  clearTimeout(frame.nearTimer)
  frame.nearTimer = setTimeout(() => prefetchAfter(step), entryTime())
}

// 걸음이 멎은 뒤 다음 걸음의 그림 한 장만.
function prefetchAfter(step) {
  if (saveData()) return
  const next = STEPS[STEPS.indexOf(step) + 1]
  if (next) shot(SHOT[next])?.classList.add("is-near")
}

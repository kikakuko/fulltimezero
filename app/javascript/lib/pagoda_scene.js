// This app is a raft. — 이 앱도 뗏목이다.
//
// 글씨가 탑으로 가는 장면.
//
// 방금 쓴 글씨가 작아지며 탑의 제 자리로 날아가 앉고, 탑 전체가 잠깐
// 보였다가 사라진다. 잠깐이어야 한다 — 머물게 하면 사용자가 자기 탑을
// 세게 된다. 그래서 장면이 끝나면 탑은 어디에도 남지 않는다.
//
// 탑은 서버가 보낸 것만 그린다. 서버는 쓴 칸의 자리만 보내므로, 여기서는
// 빈 격자를 그리고 싶어도 그릴 수 없다. 윤곽선은 칸이 아니라 층이다.
import { outline, VIEW } from "lib/brush"

const SVG = "http://www.w3.org/2000/svg"
const OPEN = 250    // 탑이 떠오르는 동안
const FLIGHT = 800  // 글씨가 날아가 앉는 동안 — 이 길이는 그대로 둔다
const HOLD = 1500   // 탑 전체가 보이는 동안 — 잠깐
const CLOSE = 300   // 사라지는 동안

// 날아가는 결. 던진 것이 그리는 호(弧)와, 앉기 전의 잠깐 지나침.
const ARC = 0.18      // 두 자리 사이 거리에 견준 솟음
const ARC_MOST = 90   // 그래도 이만큼 넘게 솟지는 않는다
const OVERSHOOT = 2   // 제 자리보다 이만큼 더 갔다가 되돌아온다
const SETTLE = 0.86   // 되돌아오기 시작하는 때

export async function playScene({ scene, flier, label, reduced, onLand }) {
  const overlay = document.createElement("div")
  overlay.className = "pagoda-scene"

  const [width, height] = scene.view
  const svg = node("svg", { viewBox: `0 0 ${width} ${height}`, class: "pagoda", role: "img", "aria-label": label })
  scene.outline.forEach(d => svg.append(node("path", { d, class: "pagoda__outline" })))
  scene.eaves.forEach(d => svg.append(node("path", { d, class: "pagoda__eave" })))

  const fresh = scene.cells.find(cell => cell.fresh)
  scene.cells.filter(cell => !cell.fresh).forEach(cell => svg.append(glyph(cell)))
  scene.bells.filter(bell => !bell.fresh).forEach(bell => svg.append(windBell(bell)))

  overlay.append(svg)
  document.body.append(overlay)

  let skipped = false
  overlay.addEventListener("click", () => { skipped = true })

  await frame()
  overlay.classList.add("is-open")
  await wait(reduced ? 0 : OPEN)

  if (fresh && flier && !reduced) await fly(flier, svg, fresh)
  if (fresh) svg.append(glyph(fresh, { settling: !reduced }))
  scene.bells.filter(bell => bell.fresh).forEach(bell => svg.append(windBell(bell, { stirred: !reduced })))
  onLand?.()

  await wait(HOLD, () => skipped)
  overlay.classList.add("is-closing")
  await wait(reduced ? 0 : CLOSE)
  overlay.remove()
}

// 한 자 — 사용자가 쓴 획 그대로. 활자로 대신 채우지 않는다.
// 방금 올린 자만 주사로 찍힌다(pagoda__fresh) — 하루에 한 번 보이는 붉은색.
// 앉는 순간 한 번 움츠렸다 펴진다 — 먹이 종이에 닿아 번지듯이.
function glyph(cell, { settling = false } = {}) {
  const kind = [ "pagoda__ink", cell.fresh && "pagoda__fresh", cell.fresh && settling && "pagoda__settling" ]
  const box = node("svg", { x: cell.x, y: cell.y, width: cell.size, height: cell.size, viewBox: `0 0 ${VIEW} ${VIEW}`,
                            class: kind.filter(Boolean).join(" ") })
  box.style.transformOrigin = `${cell.x + cell.size / 2}px ${cell.y + cell.size / 2}px`
  cell.paths.forEach(points => box.append(node("path", { d: outline(points) })))
  return box
}

// 한 층이 차면 처마 양 끝에 풍경이 걸린다. 소리는 없다.
// 막 걸린 풍경만 한 번 흔들렸다 멈춘다 — 한 층에 한 번뿐이라 흔해지지 않는다.
// 자리는 붙박이(transform 속성)로 두고, 흔들림은 그 안에서만 일어난다.
function windBell({ x, y }, { stirred = false } = {}) {
  const place = node("g", { transform: `translate(${x} ${y}) scale(1.7)` })
  const bell = node("g", { class: stirred ? "pagoda__bell pagoda__bell--stirred" : "pagoda__bell" })
  bell.append(node("path", { d: "M 0 0 V 7" }))
  bell.append(node("path", { d: "M -2.6 12 L -1.8 7 H 1.8 L 2.6 12 Z" }))
  bell.append(node("circle", { cx: 0, cy: 13.4, r: 0.9 }))
  place.append(bell)
  return place
}

// 쓰는 자리의 글씨를 탑의 칸까지 옮긴다 — 작아지며 날아가 앉는다.
async function fly({ rect, content }, svg, cell) {
  const target = screenBox(svg, cell)

  const plane = document.createElement("div")
  plane.className = "pagoda-flier"
  Object.assign(plane.style, { left: `${rect.left}px`, top: `${rect.top}px`, width: `${rect.width}px`, height: `${rect.height}px` })

  const canvas = node("svg", { viewBox: `0 0 ${VIEW} ${VIEW}`, width: "100%", height: "100%" })
  canvas.append(content)
  plane.append(canvas)
  document.body.append(plane)

  const scale = target.width / rect.width
  const dx = target.left - rect.left
  const dy = target.top - rect.top

  await plane.animate(flightPath(dx, dy, scale), { duration: FLIGHT, easing: "linear", fill: "forwards" }).finished

  plane.remove()
}

// 던진 것이 그리는 길. 가로는 처음부터 끝까지 고르게 가고, 세로는 먼저
// 솟아 제 자리보다 높이 올라갔다가 내려앉는다. 끝에서는 자리를 조금
// 지나쳤다가 되돌아온다 — 무게가 있는 것처럼.
//
// 가로 · 세로에 서로 다른 결을 주어야 하므로 easing 하나로는 안 되고,
// 길 위의 점을 찍어 넘긴다.
function flightPath(dx, dy, scale) {
  const lift = Math.min(ARC_MOST, Math.hypot(dx, dy) * ARC)
  const steps = 16
  const frames = []

  // 지나침은 가던 쪽으로. 탑이 위에 있으면 위로, 아래에 있으면 아래로.
  const beyond = dy + Math.sign(dy || 1) * OVERSHOOT

  for (let step = 0; step <= steps; step++) {
    const offset = (step / steps) * SETTLE
    const t = step / steps
    const x = dx * t
    // 세로는 일찍 다다르고(1 - (1 - t)^2), 솟음이 그 위로 얹혔다 가라앉는다.
    const y = beyond * (1 - (1 - t) ** 2) - lift * Math.sin(Math.PI * t)
    const frame = { offset, transform: `translate(${x}px, ${y}px) scale(${1 + (scale - 1) * t})` }

    // 마지막 한 칸 — 되돌아와 앉는 동안은 느려진다.
    if (step === steps) frame.easing = "ease-out"
    frames.push(frame)
  }

  frames.push({ offset: 1, transform: `translate(${dx}px, ${dy}px) scale(${scale})` })
  return frames
}

// 탑 그림 안의 칸이 화면의 어디에 있는지.
function screenBox(svg, cell) {
  const matrix = svg.getScreenCTM()
  const point = (x, y) => new DOMPoint(x, y).matrixTransform(matrix)
  const from = point(cell.x, cell.y)
  const to = point(cell.x + cell.size, cell.y + cell.size)

  return { left: from.x, top: from.y, width: to.x - from.x }
}

function node(name, attributes = {}) {
  const element = document.createElementNS(SVG, name)
  Object.entries(attributes).forEach(([key, value]) => element.setAttribute(key, value))
  return element
}

const frame = () => new Promise(resolve => requestAnimationFrame(() => resolve()))

// 기다리되, 사용자가 누르면 곧장 끝낸다.
function wait(ms, stop = () => false) {
  return new Promise(resolve => {
    const began = performance.now()
    const tick = () => (performance.now() - began >= ms || stop()) ? resolve() : requestAnimationFrame(tick)
    tick()
  })
}

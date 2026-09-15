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
const FLIGHT = 800  // 글씨가 날아가 앉는 동안
const HOLD = 1500   // 탑 전체가 보이는 동안 — 잠깐
const CLOSE = 300   // 사라지는 동안

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
  if (fresh) svg.append(glyph(fresh))
  scene.bells.filter(bell => bell.fresh).forEach(bell => svg.append(windBell(bell)))
  onLand?.()

  await wait(HOLD, () => skipped)
  overlay.classList.add("is-closing")
  await wait(reduced ? 0 : CLOSE)
  overlay.remove()
}

// 한 자 — 사용자가 쓴 획 그대로. 활자로 대신 채우지 않는다.
// 방금 올린 자만 주사로 찍힌다(pagoda__fresh) — 하루에 한 번 보이는 붉은색.
function glyph(cell) {
  const kind = cell.fresh ? "pagoda__ink pagoda__fresh" : "pagoda__ink"
  const box = node("svg", { x: cell.x, y: cell.y, width: cell.size, height: cell.size, viewBox: `0 0 ${VIEW} ${VIEW}`, class: kind })
  cell.paths.forEach(points => box.append(node("path", { d: outline(points) })))
  return box
}

// 한 층이 차면 처마 끝에 풍경이 하나 걸린다. 소리는 없다.
function windBell({ x, y }) {
  const bell = node("g", { class: "pagoda__bell", transform: `translate(${x} ${y}) scale(1.7)` })
  bell.append(node("path", { d: "M 0 0 V 7" }))
  bell.append(node("path", { d: "M -2.6 12 L -1.8 7 H 1.8 L 2.6 12 Z" }))
  bell.append(node("circle", { cx: 0, cy: 13.4, r: 0.9 }))
  return bell
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

  await plane.animate(
    [ { transform: "translate(0, 0) scale(1)" }, { transform: `translate(${dx}px, ${dy}px) scale(${scale})` } ],
    { duration: FLIGHT, easing: "cubic-bezier(0.45, 0, 0.2, 1)", fill: "forwards" }
  ).finished

  plane.remove()
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

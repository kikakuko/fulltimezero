// This app is a raft. — 이 앱도 뗏목이다.
//
// 선방의 걸음 사이 뒤로 가기를 Turbo 보다 먼저 받는 손. 브라우저는 window 에 단 popstate 손을 단 차례대로
// 부르므로(2026-11-05, 실제 브라우저에서 확인), 이 모듈은 application.js 에서 Turbo 보다 먼저 불린다. 같은 쪽의
// 걸음(state.seonbang)이면 선방이 받고 거기서 멈춘다 — Turbo 가 쪽을 다시 그리면 앉는 중의 화면이 다시 서기 때문이다.
// 다른 쪽으로 가는 뒤로 가기는 건드리지 않는다.
export const steps = { handle: null }

window.addEventListener("popstate", event => {
  if (steps.handle?.(event.state)) event.stopImmediatePropagation()
})

// This app is a raft. — 이 앱도 뗏목이다.
//
// 진동. 이 앱에서 기기를 떨게 하는 유일한 파일이다 — 다른 어디에도
// navigator.vibrate 가 있어서는 안 된다(test/integration/silence_test.rb).
//
// 울릴지 말지는 서버의 침묵 게이트가 이미 정해서 건네준다. 사용자가 손을
// 댄 그 순간에만 떤다. 앱이 먼저 떨게 하는 일은 없다(SPIRIT 제4조).
// 아이폰 사파리에는 진동이 없다. 그때는 조용히 건너뛴다.
export function touch(pattern, allowed) {
  if (!allowed) return
  if (typeof navigator.vibrate !== "function") return

  navigator.vibrate(pattern)
}

# This app is a raft. — 이 앱도 뗏목이다.
#
# 화면에 나가는 글에 거는 자물쇠. 로케일 카피에도, 파일에서 오는
# 데이터(경전·아홉 자리)에도 같은 자물쇠를 건다. 정규식이 여러 곳에
# 흩어지면 한쪽만 느슨해지므로 여기 한 곳에 둔다.
module CopyLocks
  # 이 앱은 쉼을 가르치지 않는다 — 쉬는 마음이 형상을 얻게 할 뿐이다(SPIRIT §5).
  TEACHING = {
    # 정진(精進)은 애쓰는 힘의 말이고, 완료는 달성의 말이다.
    "ko" => /수행|훈련|연습|정진|단계|레벨|달성|완료/,
    "en" => /\bpracti[cst]|\btraining\b|\bexercis|\bstages?\b|\blevels?\b|\bachiev/i
  }.freeze

  DIGIT = /\d/
  EXCLAMATION = /!/
  EMOJI = /[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/

  # 한 줄이 화면에 나가도 되는지. 걸리는 자물쇠의 이름을 돌려준다.
  def self.breaks(line)
    {
      "가르침" => TEACHING.values.any? { |re| line.match?(re) },
      "숫자" => line.match?(DIGIT),
      "느낌표" => line.match?(EXCLAMATION),
      "이모지" => line.match?(EMOJI)
    }.select { |_, broken| broken }.keys
  end
end

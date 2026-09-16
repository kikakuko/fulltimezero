# This app is a raft. — 이 앱도 뗏목이다.
#
# 화면에 나가는 글에 거는 자물쇠. 로케일 카피에도, 파일에서 오는
# 데이터(경전·아홉 자리)에도 같은 자물쇠를 건다. 정규식이 여러 곳에
# 흩어지면 한쪽만 느슨해지므로 여기 한 곳에 둔다.
#
# 금지어는 언어별로 나뉜다. 셋째 언어가 오면 그 언어의 목록을 WORDS 에
# 더한다 — 빠진 언어가 있으면 languages_test 가 깨진다. 한 항목의 뜻은
# 같되 낱말은 그 언어의 것이어야 한다. 기계 번역으로 채우지 않는다.
module CopyLocks
  WORDS = {
    "ko" => {
      # 이 앱은 쉼을 가르치지 않는다 — 쉬는 마음이 형상을 얻게 할 뿐이다(SPIRIT §5).
      # 정진(精進)은 애쓰는 힘의 말이고, 완료는 달성의 말이다.
      teaching: /수행|훈련|연습|정진|단계|레벨|달성|완료/,
      # 등급표의 말. 이 앱에는 단계도 수준도 없다(제3조).
      grading: /단계|수준|진도|초급|중급|고급/,
      # 시키는 말.
      commanding: /하라|해라|해\s?보라|하십시오|해야 한다|하세요/,
      # 부추기는 말 — 짧은 줄에 걸린다.
      urging: /하자$|해보|해\s?봐|하세요|하십시오|하라$|해라$|합시다/,
      # 읽는 이의 상태를 규정하거나 값매기는 말.
      diagnosing: /당신(은|이|의)\s*\S*\s*(아직|이미|충분|부족|잘못|못하)|(당신|너)의 (마음|상태|수준)/,
      # 읽는 이를 부르는 말 — 주어는 도상이지 사용자가 아니다.
      addressing: /당신|너의/,
      # 칭찬. 문은 그냥 열린다.
      praise: /잘했|훌륭|대단|축하|멋지/,
      # 나무람. 빈 날의 축하가 바쁜 날의 비난이 되어서는 안 된다.
      blame: /못|실패|아쉽|부족/,
      # 세는 말. 합계도 연속기록도 없다.
      counting: /연속|합계|모두|번째/,
      # 문의 이름. 문은 형상으로만.
      gate_names: /일주문|천왕문|금강문|불이문|해탈문|신장|사천왕/
    },
    "en" => {
      teaching: /\bpracti[cst]|\btraining\b|\bexercis|\bstages?\b|\blevels?\b|\bachiev/i,
      grading: /\bstage\b|\blevel\b|\bbeginner\b|\badvanced\b/i,
      commanding: /\byou (must|should|need to)\b|\bmake sure\b/i,
      urging: /\b(?:let'?s|try|keep going|you can do)\b/i,
      diagnosing: /\byou are (still|already|not)\b|\byour (mind|state|level|progress)\b/i,
      addressing: /\byou\b|\byour\b/i,
      praise: /well done|great|good job|congrat|nice|amazing/i,
      blame: /failed|should have|too much/i,
      counting: /streak|total|in a row/i,
      gate_names: /il-?ju|cheonwang|buri-?mun|one[- ]pillar|heavenly kings|non-?duality|guardians?/i
    }
  }.freeze

  CATEGORIES = WORDS.fetch("ko").keys.freeze

  DIGIT = /\d/
  EXCLAMATION = /!/
  EMOJI = /[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/

  # 한 항목의 정규식 — 언어 하나, 또는 모든 언어를 합친 것.
  def self.pattern(category, locale = nil)
    lists = locale ? [ WORDS.fetch(locale.to_s) ] : WORDS.values

    Regexp.union(lists.map { |words| words.fetch(category) })
  end

  # 한 줄이 화면에 나가도 되는지. 걸리는 자물쇠의 이름을 돌려준다.
  def self.breaks(line)
    {
      "가르침" => line.match?(pattern(:teaching)),
      "숫자" => line.match?(DIGIT),
      "느낌표" => line.match?(EXCLAMATION),
      "이모지" => line.match?(EMOJI)
    }.select { |_, broken| broken }.keys
  end
end

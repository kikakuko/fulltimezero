# This app is a raft. — 이 앱도 뗏목이다.
#
# 경내(境內) — 삼문을 지나면 서는 곳. 마당에서 전각으로 가는 길은 이름뿐이다.
# 방은 장소이지 할 일이 아니다 — 「선방 · 열두 분」 같은 시간도 설명도 붙이지
# 않는다.
#
# 조감도(compound.webp) 위의 누르는 자리. 그림 크기에 대한 백분율이다 —
# 가운데(cx, cy)와 너비 · 높이(w, h). 그림이 바뀌면 여기만 고친다.
#
# scripture — 카드의 한 줄이 경의 말인가. 경의 말만 인용 부품(.verse, 글씨의 황토)으로
# 선다. 미륵당의 한 줄은 우리가 지은 말이고 출전은 장소라 먹으로 선다.
#
# han(한자)은 언어를 가르지 않는다 — 글자 자체는 번역할 것이 아니다.
# 한 줄 · 경구 · 출전 · 「드는」 말은 config/locales 에서 온다(Localized 와
# 같은 결 — 화면의 글은 로케일 파일에만 있다).
class Compound
  Hall = Data.define(:key, :cx, :cy, :w, :h, :han, :scripture) do
    def initialize(scripture: true, **rest) = super
    def left = cx - w / 2.0
    def top = cy - h / 2.0
  end

  HALLS = [
    Hall.new(key: :sitting, cx: 17.6, cy: 39.1, w: 26.0, h: 23.4, han: "禪房"),    # 선방 — 앉기
    Hall.new(key: :maitreya, cx: 52.1, cy: 33.2, w: 14.3, h: 15.6, han: "彌勒堂", scripture: false), # 미륵당 — 날들
    Hall.new(key: :copying, cx: 80.7, cy: 38.1, w: 28.6, h: 23.4, han: "寫經室"),  # 사경실 — 사경
    Hall.new(key: :lecture, cx: 28.0, cy: 62.5, w: 32.6, h: 25.4, han: "講院"),    # 강원 — 쉼의 안내
    Hall.new(key: :courtyard, cx: 52.1, cy: 55.7, w: 28.6, h: 21.5, han: nil, scripture: false),     # 마당 — 아래로, 비움 선언
    Hall.new(key: :gate, cx: 51.4, cy: 79.1, w: 13.0, h: 15.6, han: "門")          # 문 — 처음의 문 다시
  ].freeze

  # 카드를 열고 드는 흐름이 있는 전각. 마당은 스스로를 가리키므로 카드가 없다 —
  # 누르면 곧장 아래로 간다.
  CARD_HALLS = HALLS.reject { |hall| hall.key == :courtyard }.freeze
end

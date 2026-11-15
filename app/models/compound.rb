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
# 2026-11-15 새 톤의 조감도(조감도 d 편집본, docs/M-art-renewal.md)로 갈아 끼웠다 — 범종각까지 그림에 서고,
# 묘적광전(妙寂光殿)이 여덟째 전각으로 마당 뒤 가운데에 선다. 안쪽 이름은 다루는 것을 가리킨다(:offering —
# 공양, 염불 · 향 · 등). 화면 이름은 전각을 가리킨다(CLAUDE.md).
class Compound
  Hall = Data.define(:key, :cx, :cy, :w, :h, :han, :scripture) do
    def initialize(scripture: true, **rest) = super
    def left = cx - w / 2.0
    def top = cy - h / 2.0
  end

  HALLS = [
    # 자리와 크기는 조감도(compound.webp, 768×512 — 조감도 d 편집본을 3:2 로 자른 것)에서 잰 백분율이다. 그림이 바뀌면
    # 여기만 고친다 — 2026-11-15 에 새 톤의 조감도로 갈아 끼우며 아홉을 다시 쟀다. 이름의 높이는 CSS 의 --name-y 가
    # 전각마다 맞춘다(붙어 선 전각끼리 이름이 겹치지 않게).
    Hall.new(key: :offering, cx: 50.5, cy: 30.5, w: 20.0, h: 18.0, han: "妙寂光殿"),                  # 묘적광전 — 공양
    Hall.new(key: :bowing, cx: 37.0, cy: 33.5, w: 7.0, h: 9.0, han: "禮敬堂", scripture: false),       # 예경당 — 절
    Hall.new(key: :maitreya, cx: 86.0, cy: 35.0, w: 16.0, h: 13.0, han: "彌勒堂", scripture: false),   # 미륵당 — 날들(미륵 터)
    Hall.new(key: :copying, cx: 68.0, cy: 37.0, w: 12.0, h: 16.0, han: "寫經室"),                       # 사경실 — 사경
    Hall.new(key: :sitting, cx: 27.5, cy: 38.5, w: 11.0, h: 14.0, han: "禪房"),                         # 선방 — 앉기
    # 마당 — 불이문 앞의 아랫마당. 아래로, 비움 선언.
    Hall.new(key: :courtyard, cx: 63.0, cy: 54.0, w: 10.0, h: 6.0, han: nil, scripture: false),
    Hall.new(key: :lecture, cx: 20.5, cy: 50.0, w: 15.0, h: 18.0, han: "藏經閣"),                       # 장경각 — 쉼의 안내
    Hall.new(key: :bell, cx: 76.5, cy: 50.5, w: 11.0, h: 18.0, han: "梵鐘閣", scripture: false),        # 범종각 — 소리
    # 마당의 담에 선 문은 셋째 문(불이문)이다 — 이 문을 지나 마당에 섰다. 누르면 처음의 문부터 다시.
    Hall.new(key: :gate, cx: 50.0, cy: 46.0, w: 7.5, h: 10.0, han: "不二門")                            # 불이문 — 처음의 문 다시
  ].freeze

  # 카드를 열고 드는 흐름이 있는 전각. 마당은 스스로를 가리키므로 카드가 없다 —
  # 누르면 곧장 아래로 간다.
  CARD_HALLS = HALLS.reject { |hall| hall.key == :courtyard }.freeze

  def self.hall(key) = HALLS.find { |hall| hall.key == key.to_sym } or raise ArgumentError, "모르는 전각: #{key}"
end

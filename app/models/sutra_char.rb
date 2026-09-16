# This app is a raft. — 이 앱도 뗏목이다.
#
# 경의 한 자. 사경에서 하루에 만나는 그 한 자다.
#
# nth · total 은 이 자가 경 안에서 몇 번째로, 모두 몇 번 나오는지다.
# 데이터로만 쥐고 있을 뿐, 화면에 숫자로 내보이지 않는다(SPIRIT 숫자 규정).
class SutraChar < ApplicationRecord
  include Localized

  belongs_to :sutra
  belongs_to :phrase, class_name: "SutraPhrase", foreign_key: :sutra_phrase_id

  validates :pos, :glyph, :reading, :sense_here, :gloss_en, :nth, :total, presence: true

  # 산스크리트를 소리로 옮긴 자.
  def transliterated? = sanskrit.present?

  # 언어별 칸의 규칙은 Localized 한 곳에 있다.
  # 훈음은 한국어의 것이라 다른 언어에서는 비운다. 이 자리의 뜻은 영어로는
  # 영어 풀이(gloss_en)가 맡는다.
  localized :sense_here, korean_only: %i[reading sound]
  def sense_here_en = gloss_en

  # 음역자의 소리 — 한국어의 것.
  def sound = sanskrit&.dig("sound_ko")

  # 영어 풀이는 뜻이 이미 영어일 때는 따로 적지 않는다.
  def gloss_beside = (gloss_en unless sense_here_here == gloss_en)
end

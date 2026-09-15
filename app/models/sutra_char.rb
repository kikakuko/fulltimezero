# This app is a raft. — 이 앱도 뗏목이다.
#
# 경의 한 자. 사경에서 하루에 만나는 그 한 자다.
#
# nth · total 은 이 자가 경 안에서 몇 번째로, 모두 몇 번 나오는지다.
# 데이터로만 쥐고 있을 뿐, 화면에 숫자로 내보이지 않는다(SPIRIT 숫자 규정).
class SutraChar < ApplicationRecord
  belongs_to :sutra
  belongs_to :phrase, class_name: "SutraPhrase", foreign_key: :sutra_phrase_id

  validates :pos, :glyph, :reading, :sense_here, :gloss_en, :nth, :total, presence: true

  # 산스크리트를 소리로 옮긴 자.
  def transliterated? = sanskrit.present?
end

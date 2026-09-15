# This app is a raft. — 이 앱도 뗏목이다.
#
# 경의 한 구절. 글자들이 모여 뜻이 되는 자리다.
class SutraPhrase < ApplicationRecord
  belongs_to :sutra
  has_many :chars, -> { order(:pos) }, class_name: "SutraChar", dependent: :destroy

  validates :number, :han, :ko, :en, :start_pos, :end_pos, presence: true

  def span = start_pos..end_pos
end

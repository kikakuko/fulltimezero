# This app is a raft. — 이 앱도 뗏목이다.
#
# 일정 하나. 날짜와 한 줄이 전부다.
#
# 시각을 두지 않는다 — 몇 시 몇 분을 적기 시작하면 이 화면은 달력이
# 아니라 일정 관리 도구가 되고, 그때부터 빈 날은 실패로 읽힌다.
# 개수를 세지 않는다. 화면에 「몇 건」이 뜨는 순간 그것은 지표가 된다.
class Plan < ApplicationRecord
  MOST = 60

  belongs_to :user

  validates :planned_on, presence: true
  validates :what, presence: true, length: { maximum: MOST }

  normalizes :what, with: ->(what) { what.strip }

  scope :on, ->(date) { where(planned_on: date) }
  scope :chronological, -> { order(:created_at) }
end

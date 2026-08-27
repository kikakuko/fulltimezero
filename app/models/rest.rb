# This app is a raft. — 이 앱도 뗏목이다.
#
# 쉼 한 건.
#
# 절대 규칙:
#   - duration 은 분으로 환산되지 않는다. 쉼을 분으로 재지 않는다.
#   - texture(쉼의 결) 사이에 위계가 없다. 달 계산과 화면 어디에서도
#     결에 가중치를 주지 않는다. 모든 결은 동등하다.
#   - 평가·판정 속성을 두지 않는다(SPIRIT 제3조).
class Rest < ApplicationRecord
  # 목록 순서는 표시 순서일 뿐, 깊이의 순위가 아니다.
  # "time_fell_away"(시간을 잊었다)는 거절 선택지가 아니라
  # 가장 깊은 쉼의 자기보고이며, 다른 항목과 동등한 무게로 다룬다.
  DURATIONS = %w[one_breath a_moment a_while a_long_while time_fell_away].freeze

  # 건너뛸 수 있다. 결 사이에 순위는 없다.
  TEXTURES = %w[lay_down walked sat_still did_nothing other].freeze

  belongs_to :user

  enum :duration, DURATIONS.index_by(&:itself), validate: true
  enum :texture, TEXTURES.index_by(&:itself), validate: { allow_nil: true }

  validates :rested_on, presence: true
  validates :note, length: { maximum: 200 }

  normalizes :note, with: ->(n) { n.strip.presence }
  normalizes :texture, with: ->(t) { t.presence }

  before_validation :stamp_today, on: :create

  scope :chronological, -> { order(:rested_on, :created_at) }

  private
    def stamp_today
      self.rested_on ||= user&.today
    end
end

# This app is a raft. — 이 앱도 뗏목이다.
#
# 앉음 한 자리. 남는 것은 "그 날 앉았다"는 사실뿐이다.
#
# 절대 규칙:
#   - 길이도 분도 저장하지 않는다. 타이머의 길이는 그 자리의 설정이지
#     기록이 아니다. 앉음을 Rest 로 환산하지도 않는다 — "향 한 대 = 한동안"
#     같은 환산표는 제3조가 금한 가짜 정밀도의 부활이다.
#   - 완주·점수·품질 속성을 두지 않는다. 중간에 나가도 실패가 아니다.
#     ended_at 은 끝난 시각일 뿐이고, 시작과의 차를 재는 코드는 없다.
#   - 삼 분을 앉든 삼십 분을 앉든, 무위에 들든, 그 날은 똑같이 하나다.
#
# test/models/sitting_test.rb 가 컬럼 목록을 통째로 못박는다.
class Sitting < ApplicationRecord
  # sitting — 명상 타이머. nothing — 무위의 시간.
  MODES = %w[sitting nothing].freeze

  # 앉음은 스스로 잊힌다. 무위에는 정해진 끝이 없으므로, 오래된 자리는
  # 끝난 것으로 본다 — 그러지 않으면 앱이 영영 침묵한다.
  STALE_AFTER = 4.hours

  belongs_to :user

  validates :mode, inclusion: { in: MODES }

  scope :ongoing, -> { where(ended_at: nil).where(created_at: STALE_AFTER.ago..) }
  scope :chronological, -> { order(:created_at) }

  before_validation :stamp_day, on: :create

  def sitting? = mode == "sitting"
  def nothing? = mode == "nothing"
  def ended? = ended_at.present?

  def finish!
    update!(ended_at: Time.current) unless ended?
  end

  private
    def stamp_day
      self.sat_on ||= user&.today
    end
end

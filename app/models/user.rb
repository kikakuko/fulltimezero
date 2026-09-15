# This app is a raft. — 이 앱도 뗏목이다.
class User < ApplicationRecord
  LOCALES = %w[ko en].freeze

  # 「무엇에서 쉬려 하는가」에 적는 한 줄의 끝.
  RESTING_FROM_MOST = 200

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :rests, dependent: :destroy
  has_many :sittings, dependent: :destroy
  has_many :plans, dependent: :destroy
  has_many :clearings, dependent: :destroy
  has_many :copyings, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # 비워 두고 지나갈 수 있다. 적은 것은 받아 두기만 한다 — 분석하지도,
  # 추천에 쓰지도 않는다. 언젠가 한 번 조용히 되돌려준다(아직 만들지 않았다).
  normalizes :resting_from, with: ->(line) { line.strip.first(RESTING_FROM_MOST).presence }

  validates :email_address, presence: true, uniqueness: true

  validates :locale, inclusion: { in: LOCALES }
  validate :time_zone_must_exist

  # 처음의 문 셋을 지났는가.
  def onboarded? = onboarded_at.present?

  # "오늘"의 경계는 사용자마다 다르다.
  def today
    Time.current.in_time_zone(time_zone).to_date
  end

  def rested_today?
    rests.exists?(rested_on: today)
  end

  # 앉아 있는 동안 앱은 침묵한다(SPIRIT 제4조).
  def sitting? = sittings.ongoing.exists?

  def sat_today? = sittings.exists?(sat_on: today)

  # 오늘 일정이 하나도 없다. 개수는 세지 않는다 — 있고 없음뿐이다.
  def empty_today? = !plans.exists?(planned_on: today)

  def cleared_today? = clearings.exists?(cleared_on: today)

  def morning? = (5...11).cover?(hour_now)
  def evening? = hour_now >= 18

  # 오늘 이미 쉼이 있었거나 앉은 자리가 있었다.
  # 물음이 조름이 되지 않도록, 이 날의 화면은 다르게 묻는다.
  def quiet_today? = rested_today? || sat_today?

  def moon
    MoonPhase.for(self)
  end

  def pagoda(sutra: Sutra.heart) = Pagoda.for(self, sutra: sutra)

  private
    def hour_now = Time.current.in_time_zone(time_zone).hour

    def time_zone_must_exist
      errors.add(:time_zone, :inclusion) if ActiveSupport::TimeZone[time_zone.to_s].nil?
    end
end

# This app is a raft. — 이 앱도 뗏목이다.
class User < ApplicationRecord
  LOCALES = %w[ko en].freeze

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :rests, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true

  validates :locale, inclusion: { in: LOCALES }
  validate :time_zone_must_exist

  # "오늘"의 경계는 사용자마다 다르다.
  def today
    Time.current.in_time_zone(time_zone).to_date
  end

  def rested_today?
    rests.exists?(rested_on: today)
  end

  def moon
    MoonPhase.for(self)
  end

  private
    def time_zone_must_exist
      errors.add(:time_zone, :inclusion) if ActiveSupport::TimeZone[time_zone.to_s].nil?
    end
end

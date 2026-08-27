# This app is a raft. — 이 앱도 뗏목이다.
#
# 차오르는 달.
#
#   phase = (최근 28일 중 쉼이 기록되었거나 앉은 날의 수) / 28
#
# 연속기록이 아니다. 하루 빠뜨려도 "끊겼다"는 개념이 없고,
# 창에서 밀려나며 조용히 이지러질 뿐이다(SPIRIT 제6조).
# 하루에 몇 번을 기록하든, 몇 번을 앉든 그 날은 1로 센다.
# 어떤 결도, 어떤 길이도, 쉼이든 앉음이든 다른 것보다 무겁지 않다.
# 달은 두 곳을 함께 볼 뿐, 앉음을 쉼으로 환산하지 않는다.
class MoonPhase
  WINDOW_DAYS = 28

  attr_reader :days, :fraction

  def self.for(user, today: nil)
    today ||= user.today
    window = (today - (WINDOW_DAYS - 1))..today
    quiet = user.rests.where(rested_on: window).distinct.pluck(:rested_on) +
            user.sittings.where(sat_on: window).distinct.pluck(:sat_on)
    quiet = quiet.to_set

    new(window.to_a.map { |date| Day.new(date, quiet.include?(date)) })
  end

  Day = Struct.new(:date, :rested) do
    def rested? = rested
  end

  def initialize(days)
    @days = days
    @fraction = days.count(&:rested?).fdiv(WINDOW_DAYS)
  end

  def new_moon? = fraction.zero?
  def full_moon? = fraction >= 1.0

  # 4 x 7 격자. 마지막 칸이 오늘.
  def rows = days.each_slice(7).to_a
end

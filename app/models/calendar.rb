# This app is a raft. — 이 앱도 뗏목이다.
#
# 한 달의 격자. 날짜 숫자는 여기에만 있다 — 달력의 날짜는 본질상
# 숫자이고, 그것 말고는 어떤 숫자도 화면에 두지 않는다.
#
# 한 칸이 세 가지를 품는다: 일정이 있는 날 · 비워 둔 날 · 고요했던 날
# (쉬었거나 앉은 날). 개수는 세지 않는다 — 있고 없음뿐이다.
# 합계도 연속기록도 없다. 달력은 지나온 날들이지 성적표가 아니다.
class Calendar
  WEEK = 7

  attr_reader :month, :days

  def self.for(user, month:, today: nil)
    today ||= user.today
    span = month.beginning_of_month..month.end_of_month
    planned = user.plans.where(planned_on: span).distinct.pluck(:planned_on).to_set
    cleared = user.clearings.where(cleared_on: span).pluck(:cleared_on).to_set
    quiet = user.rests.where(rested_on: span).pluck(:rested_on).to_set +
            user.sittings.where(sat_on: span).pluck(:sat_on).to_set

    new(month, grid(month).map { |date|
      Day.new(date, planned.include?(date), cleared.include?(date), quiet.include?(date),
              date.month == month.month, date == today)
    })
  end

  # 앞뒤로 빈칸을 채워 온전한 주를 만든다.
  def self.grid(month)
    first = month.beginning_of_month
    last = month.end_of_month

    (first - first.wday)..(last + (WEEK - 1 - last.wday))
  end

  Day = Struct.new(:date, :planned, :cleared, :quiet, :inside, :today) do
    def planned? = planned
    def cleared? = cleared
    # 그 날 쉼이나 앉음이 있었다. 얼마나였는지는 묻지 않는다.
    def quiet? = quiet
    def inside? = inside
    def today? = today
    def empty? = !planned
  end

  def initialize(month, days)
    @month = month
    @days = days
  end

  def weeks = days.each_slice(WEEK).to_a
  def previous = month.prev_month
  def following = month.next_month
end

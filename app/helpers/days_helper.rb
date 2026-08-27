# This app is a raft. — 이 앱도 뗏목이다.
#
# 달 이름과 요일 이름은 글자로 적는다. 화면에서 숫자인 것은 오직
# 달력 격자 안의 날짜뿐이다(SPIRIT 형상 원칙·M3 설계).
module DaysHelper
  MONTHS = %w[january february march april may june
              july august september october november december].freeze
  WEEKDAYS = %w[sunday monday tuesday wednesday thursday friday saturday].freeze

  def month_name(date) = t("days.months.#{MONTHS[date.month - 1]}")
  def weekday_name(index) = t("days.weekdays.#{WEEKDAYS[index]}")
end

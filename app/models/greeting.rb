# This app is a raft. — 이 앱도 뗏목이다.
#
# 오늘 화면의 인사말. 계절과 요일에 따라 가끔 달라진다.
#
# 매일 있으면 반갑지 않다. 주에 한두 번쯤이면 족하다 —
# 온기는 빈도가 낮을수록 진하다(SPIRIT 형상 원칙).
# 같은 날 같은 사람에게는 늘 같은 말이 오도록 날짜에서 뽑는다.
# 새로고침할 때마다 말이 바뀌면 그것은 인사가 아니라 뽑기다.
class Greeting
  # 이레 중 이틀쯤.
  ODDS = 2
  IN = 7

  SEASONS = {
    1 => "deep_winter", 2 => "winter", 3 => "spring", 4 => "spring",
    5 => "late_spring", 6 => "summer", 7 => "deep_summer", 8 => "deep_summer",
    9 => "autumn", 10 => "autumn", 11 => "late_autumn", 12 => "winter"
  }.freeze

  def self.for(user, on: nil)
    date = on || user.today
    seed = Digest::MD5.hexdigest("#{user.id}:#{date}")[0, 8].to_i(16)

    return nil unless seed % IN < ODDS

    keys = keys_for(date)
    keys[seed / IN % keys.size]
  end

  def self.keys_for(date)
    keys = [ SEASONS.fetch(date.month) ]

    keys << "sunday" if date.sunday?
    keys << "saturday" if date.saturday?
    keys << "monday" if date.monday?
    keys << "year_end" if date.month == 12 && date.day > 20
    keys << "new_year" if date.month == 1 && date.day < 8

    keys
  end
end

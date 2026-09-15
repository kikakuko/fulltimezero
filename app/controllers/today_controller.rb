# This app is a raft. — 이 앱도 뗏목이다.
class TodayController < ApplicationController
  # 처음 온 사람은 오늘에 앞서 문 셋을 지난다.
  before_action -> { redirect_to threshold_path unless Current.user.onboarded? }

  def show
    @moon = Current.user.moon
    @quiet = Current.user.quiet_today?

    # 「오늘 몫은 끝났다」는 기록한 그 자리에서만 말한다(제2조).
    # 나중에 다시 열었을 때 같은 말을 되풀이하면 그것은 조름이 된다.
    @just_recorded = flash[:notice].present?

    # 계절과 요일의 인사. 대개는 아무 말도 없다.
    @greeting = Greeting.for(Current.user)

    # 빈 일정은 축하하고, 바쁜 날은 나무라지 않는다(제5조).
    # 바쁜 날에는 낮 내내 아무 말도 하지 않다가 저녁에야 한마디 한다.
    @empty = Current.user.empty_today?
    @day_line = if @empty then "days.empty_today"
    elsif Current.user.evening? then "days.evening"
    end

    # 비운 날의 아침 첫 화면에서만, 달이 살짝 크게 한 번 숨 쉰다.
    @cleared_morning = @empty && Current.user.morning? &&
                       session[:cleared_seen_on] != Current.user.today.to_s
    session[:cleared_seen_on] = Current.user.today.to_s if @cleared_morning
  end
end

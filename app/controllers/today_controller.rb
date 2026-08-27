# This app is a raft. — 이 앱도 뗏목이다.
class TodayController < ApplicationController
  def show
    @moon = Current.user.moon
    @quiet = Current.user.quiet_today?

    # 「오늘 몫은 끝났다」는 기록한 그 자리에서만 말한다(제2조).
    # 나중에 다시 열었을 때 같은 말을 되풀이하면 그것은 조름이 된다.
    @just_recorded = flash[:notice].present?
  end
end

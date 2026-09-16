# This app is a raft. — 이 앱도 뗏목이다.
#
# 날들. 극히 단순하게 — 날짜별로 한 줄을 적고 지운다.
# 개수를 세지 않고, 알림을 보내지 않고, 지키지 못한 비움을 되묻지 않는다.
class DaysController < ApplicationController
  def index
    @calendar = Calendar.for(Current.user, month: month)
  end

  def show
    @date = date
    @plans = Current.user.plans.on(@date).chronological
    @cleared = Current.user.clearings.exists?(cleared_on: @date)

    # 그 날 남긴 쉼과 앉음. 지우려면 먼저 보여야 한다.
    @rests = Current.user.rests.where(rested_on: @date).chronological
    @sittings = Current.user.sittings.where(sat_on: @date).chronological
  end

  # 비움 예약을 걸고 거둔다. 오가는 것뿐이라 물어보지 않는다.
  # 오늘 화면에서 선언했으면 오늘 화면으로 돌아간다.
  def update
    clearing = Current.user.clearings.find_by(cleared_on: date)

    clearing ? clearing.destroy! : Current.user.clearings.create!(cleared_on: date)

    redirect_to params[:from] == "today" ? today_path : day_path(date)
  end

  private
    def date
      Date.parse(params[:date])
    rescue Date::Error
      Current.user.today
    end

    def month
      params[:month].present? ? Date.parse("#{params[:month]}-01") : Current.user.today
    rescue Date::Error
      Current.user.today
    end
end

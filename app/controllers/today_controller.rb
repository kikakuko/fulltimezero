# This app is a raft. — 이 앱도 뗏목이다.
class TodayController < ApplicationController
  def show
    @moon = Current.user.moon
    @done = Current.user.rested_today?
  end
end

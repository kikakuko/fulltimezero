# This app is a raft. — 이 앱도 뗏목이다.
class MoonController < ApplicationController
  def show
    @moon = Current.user.moon
  end
end

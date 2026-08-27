# This app is a raft. — 이 앱도 뗏목이다.
class GateController < ApplicationController
  allow_unauthenticated_access

  def show
    redirect_to today_path if authenticated?
  end
end

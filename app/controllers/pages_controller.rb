# This app is a raft. — 이 앱도 뗏목이다.
class PagesController < ApplicationController
  allow_unauthenticated_access

  def privacy
  end

  # 가입이 닫혀 있는 동안 문 셋의 끝. 404 로 떨어뜨리지 않고 한 줄로 말한다.
  # 가입이 열려 있으면 이 화면은 설 자리가 없다 — 가입으로 보낸다.
  def not_yet
    redirect_to new_user_path and return if SignupGate.open?
  end

  # 로봇에게 하는 말. 기본은 전부 막음(SearchGate).
  def robots
    render plain: SearchGate.open? ? "User-agent: *\nAllow: /\n" : "User-agent: *\nDisallow: /\n",
           content_type: "text/plain"
  end
end

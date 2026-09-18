# This app is a raft. — 이 앱도 뗏목이다.
class PagesController < ApplicationController
  allow_unauthenticated_access

  def privacy
  end

  # 로봇에게 하는 말. 기본은 전부 막음(SearchGate).
  def robots
    render plain: SearchGate.open? ? "User-agent: *\nAllow: /\n" : "User-agent: *\nDisallow: /\n",
           content_type: "text/plain"
  end
end

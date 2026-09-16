# This app is a raft. — 이 앱도 뗏목이다.
#
# 앱의 첫 자리. 처음 온 사람은 곧장 첫째 문 앞에 서고, 들어온 사람은
# 마당으로 간다. 설명하는 랜딩은 없다 — 문이 랜딩이다.
class GateController < ApplicationController
  allow_unauthenticated_access

  def show
    redirect_to authenticated? ? today_path : threshold_path
  end
end

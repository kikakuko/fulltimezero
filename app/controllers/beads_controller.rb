# This app is a raft. — 이 앱도 뗏목이다.
#
# 알 하나 — 절 한 배의 끝.
#
# 앱이 저절로 꿰지 않는다. 사람이 절하고 사람이 누른다.
# 지우는 길은 없다 — 꿰인 알은 풀리지 않는다(§3).
class BeadsController < ApplicationController
  def create
    kind = params[:kind].to_s
    return head :not_found unless Bowing.kind?(kind)

    rosary = Rosary.for(Current.user, kind: kind)
    Current.user.beads.create!(kind: kind, round: rosary.round)
    strung = Current.user.beads.where(kind: kind, round: rosary.round).count

    # 한 배가 끝났으니 그 한 배를 보여 준다. 백여덟 번째에만 원이 닫힌다.
    flash[:bowed] = true
    flash[:closed] = true if rosary.closed?(strung)

    redirect_to bow_path(kind)
  end
end

# This app is a raft. — 이 앱도 뗏목이다.
#
# 절. 고르는 자리와 절하는 자리.
#
# 고르는 자리에는 설명이 없다 — 그림만 보이고 고른다(§2). 어느 쪽이 깊다거나
# 낫다고 말하지 않는다(§5).
#
# 절하는 자리에서 앱이 하는 일은 칸을 넘기는 것뿐이다. 세는 것은 사람이고,
# 알은 사람이 누를 때 꿰인다.
class BowsController < ApplicationController
  def show
  end

  def bow
    @kind = params[:kind]
    return redirect_to bows_path unless Bowing.kind?(@kind)

    @form = Bowing.form(@kind)
    @marks = Bowing.marks(@kind)
    @rosary = Rosary.for(Current.user, kind: @kind)
  end
end

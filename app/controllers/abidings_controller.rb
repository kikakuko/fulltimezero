# This app is a raft. — 이 앱도 뗏목이다.
#
# 아홉 자리 가운데 하나. 읽는 곳이다 — 앱이 자리를 정해 주지 않고,
# 읽고 나서 앉을 때 고른다. 어느 자리든 처음부터 열려 있다.
class AbidingsController < ApplicationController
  allow_unauthenticated_access

  def show
    @abiding = Abiding.find_by(pos: params[:pos])

    redirect_to guide_chapter_path("abidings") unless @abiding
  end
end

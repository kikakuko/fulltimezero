# This app is a raft. — 이 앱도 뗏목이다.
#
# 탑을 보는 자리.
#
# 아홉 달을 쌓는 것을 하루 한 번 잠깐만 보게 하는 것은 가혹하다. 달의
# 자취도 코끼리의 길도 언제든 볼 수 있는데 탑만 못 볼 까닭이 없다.
#
# 세는 것을 막는 일은 화면이 이미 한다 — 숫자가 없고, 빈 칸이 없고,
# 몇 층인지 적지 않는다. 쓴 자리만 그린다.
class PagodasController < ApplicationController
  def show
    @scene = PagodaLayout.scene(Current.user.copyings.includes(:sutra_char))
  end
end

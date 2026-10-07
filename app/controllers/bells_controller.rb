# This app is a raft. — 이 앱도 뗏목이다.
#
# 범종각. 종을 한 번 치고 소리가 사라질 때까지 듣는다. 그것이 전부다.
#
# 여섯 전각 가운데 유일하게 **아무것도 쌓지 않는다.** 달도 탑도 코끼리도
# 미륵도 염주도 여기에는 없다. 몇 번 쳤는지 세지 않고, 얼마나 들었는지
# 재지 않는다. 쓰는 길이 아예 없다(bell_hall_test, 약속).
#
# 「소리는 사라진다」가 이 전각이 말하는 전부이고, 그 말도 소리로만 한다.
class BellsController < ApplicationController
  def show
    # 울릴지 말지는 화면이 아니라 게이트가 정한다. 스스로 친 종은 청한 소리라
    # 밤에도 울린다(SilenceGate 의 ALWAYS_AUDIBLE).
    @bell = SilenceGate.allow?(:bell, user: Current.user)
  end
end

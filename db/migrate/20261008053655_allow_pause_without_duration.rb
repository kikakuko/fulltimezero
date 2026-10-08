# This app is a raft. — 이 앱도 뗏목이다.
#
# 틈 — 마당의 낙관을 누른 쉼은 길이를 묻지 않는다. 길이가 없는 쉼이 설 수 있어야 한다.
# 컬럼은 늘지 않는다. 결(texture)은 본디 비어도 되었다.
class AllowPauseWithoutDuration < ActiveRecord::Migration[8.1]
  def change
    change_column_null :rests, :duration, true
  end
end

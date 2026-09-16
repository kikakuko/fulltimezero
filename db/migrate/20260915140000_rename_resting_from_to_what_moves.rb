# This app is a raft. — 이 앱도 뗏목이다.
#
# 둘째 문의 물음이 「무엇에서 쉬려 하는가」에서 「무엇이 움직이는가」로
# 바뀌었다. 물음이 바뀌면 답의 뜻도 달라진다 — 칸 이름은 그 안에 든 것이
# 무엇인지에 대한 주장이므로 함께 바꾼다.
#
# 이 개정 전에 적힌 답은 다른 물음, 곧 「무엇에서 쉬려 하는가」에 대한
# 것이었다. 사용자의 것이므로 지우지도 고치지도 않고 그대로 옮겨 둔다.
class RenameRestingFromToWhatMoves < ActiveRecord::Migration[8.1]
  def change
    rename_column :users, :resting_from, :what_moves
  end
end

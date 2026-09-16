# This app is a raft. — 이 앱도 뗏목이다.
#
# 오늘을 비울 때의 종성. 기본은 꺼짐이다 — 소리는 부르지 않았는데 오는
# 것이어서는 안 된다. 켜는 것은 설정에서, 사용자가 한다.
class AddClearingSoundToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :clearing_sound, :boolean, default: false, null: false
  end
end

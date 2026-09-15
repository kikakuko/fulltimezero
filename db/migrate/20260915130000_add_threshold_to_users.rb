# This app is a raft. — 이 앱도 뗏목이다.
#
# 처음의 문 셋.
#
#   onboarded_at  문 셋을 지난 때. 비어 있으면 아직 문 앞이다.
#   resting_from  「무엇에서 쉬려 하는가」에 적은 한 줄. 비워 둘 수 있다.
#                 분석하지도, 추천에 쓰지도 않는다. 받아 두었다가 언젠가
#                 한 번 조용히 되돌려준다(아직 만들지 않았다).
#   daily_door    앱을 열 때마다 숨 한 번 쉬는 어둠. 설정에서 끌 수 있다.
class AddThresholdToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :onboarded_at, :datetime
    add_column :users, :resting_from, :text
    add_column :users, :daily_door, :boolean, null: false, default: true
  end
end

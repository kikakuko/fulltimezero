# This app is a raft. — 이 앱도 뗏목이다.
#
# 염주 한 알 — 절 한 배의 끝. 한 알이 한 줄이다.
#
# 점수도 등급도 없다. 얼마나 걸렸는지, 얼마나 깊이 숙였는지 적지 않는다.
# 알은 꿰이기만 하고 풀리지 않는다(§3 쌓인 것은 무너지지 않는다).
class CreateBeads < ActiveRecord::Migration[8.1]
  def change
    create_table :beads do |t|
      t.references :user, null: false, foreign_key: true
      # 어느 벌로 절했는가 — 한국식 큰절인지 티베트식 오체투지인지.
      t.string :kind, null: false
      # 몇 번째 염주인가. 백여덟이 차면 다음 염주가 시작된다.
      t.integer :round, null: false, default: 1
      t.timestamps
    end

    add_index :beads, [ :user_id, :round ]
  end
end

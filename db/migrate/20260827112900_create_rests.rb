# This app is a raft. — 이 앱도 뗏목이다.
#
# 쉼 한 건. 평가성 컬럼(점수·등급·기분·품질)은 두지 않는다 — SPIRIT 제3조.
# 분(minutes)을 저장하지 않는다 — 쉼을 분으로 재지 않는다.
class CreateRests < ActiveRecord::Migration[8.1]
  def change
    create_table :rests do |t|
      t.references :user, null: false, foreign_key: true
      t.date   :rested_on, null: false
      t.string :duration,  null: false
      t.string :texture                 # 선택. 건너뛸 수 있다
      t.text   :note

      t.timestamps
    end

    add_index :rests, [ :user_id, :rested_on ]
  end
end

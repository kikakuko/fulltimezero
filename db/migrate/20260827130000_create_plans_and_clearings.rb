# This app is a raft. — 이 앱도 뗏목이다.
#
# 일정과 비움. 세는 것이 아니라 있고 없음이다.
class CreatePlansAndClearings < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.references :user, null: false, foreign_key: true
      t.date :planned_on, null: false
      t.string :what, null: false

      t.timestamps
    end

    add_index :plans, [ :user_id, :planned_on ]

    # 미리 비워 둔 날.
    create_table :clearings do |t|
      t.references :user, null: false, foreign_key: true
      t.date :cleared_on, null: false

      t.timestamps
    end

    add_index :clearings, [ :user_id, :cleared_on ], unique: true
  end
end

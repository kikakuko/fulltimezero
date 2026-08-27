# This app is a raft. — 이 앱도 뗏목이다.
#
# 앉음은 날짜 하나로 족하다.
# 길이도, 분도, 종성 여부도 저장하지 않는다 — 그것들은 그 자리의
# 설정이지 기록이 아니다(SPIRIT 제3조).
class CreateSittings < ActiveRecord::Migration[8.1]
  def change
    create_table :sittings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :mode, null: false
      t.date :sat_on, null: false
      t.datetime :ended_at

      t.timestamps
    end

    add_index :sittings, [ :user_id, :sat_on ]
  end
end

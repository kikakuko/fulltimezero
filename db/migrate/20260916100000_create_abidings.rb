# This app is a raft. — 이 앱도 뗏목이다.
#
# 아홉 자리(구주심). 앱의 것이지 사용자의 것이 아니다 — 값은 data/ 의
# 파일에서만 온다. 처음부터 아홉이 다 열려 있고, 읽고 고르는 안내다.
# 쉰 날의 수로 자리를 부여하지 않는다.
#
# 앉음에는 그때 고른 자리만 남는다. 비워 둘 수 있다. 어느 자리를 몇 번
# 골랐는지 세는 곳은 없다 — 고름은 기록이 아니라 그 자리의 설정에 가깝다.
class CreateAbidings < ActiveRecord::Migration[8.1]
  def change
    create_table :abidings do |t|
      t.integer :pos, null: false
      t.string :han, null: false
      t.string :ko, null: false
      t.string :sanskrit, null: false
      t.string :gloss_en, null: false
      t.string :one_line, null: false
      t.text :what_happens, null: false
      t.text :what_to_do, null: false
      t.string :power, null: false
      t.string :engagement, null: false
      t.string :hindrance, null: false
      t.text :image, null: false
      t.string :sit_hint, null: false
      t.string :one_line_en, null: false
      t.text :what_happens_en, null: false
      t.text :what_to_do_en, null: false
      t.string :power_en, null: false
      t.string :engagement_en, null: false
      t.string :hindrance_en, null: false
      t.text :image_en, null: false
      t.string :sit_hint_en, null: false
      t.timestamps
    end
    add_index :abidings, :pos, unique: true

    add_reference :sittings, :abiding, null: true, foreign_key: true
  end
end

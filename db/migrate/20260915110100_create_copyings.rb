# This app is a raft. — 이 앱도 뗏목이다.
#
# 사경 한 자. 탑의 한 칸이다.
#
# glyph_paths 가 비어 있으면 종이에 쓴 것이다 — 화면은 종이를 대신하지
# 않고 종이로 가는 문이며, 종이에 쓴 자도 똑같이 탑을 쌓는다(SPIRIT §3).
# 글씨를 채점할 칸은 두지 않는다.
class CreateCopyings < ActiveRecord::Migration[8.1]
  def change
    create_table :copyings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :sutra_char, null: false, foreign_key: true
      t.json :glyph_paths
      t.date :copied_on, null: false

      t.timestamps
    end

    add_index :copyings, [ :user_id, :copied_on ], unique: true      # 하루 한 자
    add_index :copyings, [ :user_id, :sutra_char_id ], unique: true  # 한 자는 한 번
  end
end

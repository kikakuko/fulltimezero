# This app is a raft. — 이 앱도 뗏목이다.
#
# 경전은 앱의 것이다. 사용자의 것이 아니므로 내보내기에 담지 않고,
# 계정을 지워도 남는다. 값은 data/ 의 파일에서만 들어온다.
class CreateSutras < ActiveRecord::Migration[8.1]
  def change
    create_table :sutras do |t|
      t.string :slug, null: false            # 파일의 sutra.id
      t.string :title_han, null: false
      t.string :title_ko, null: false
      t.string :edition
      t.integer :total, null: false
      t.text :translation_note
      t.integer :unique_glyphs

      t.timestamps
    end
    add_index :sutras, :slug, unique: true

    create_table :sutra_phrases do |t|
      t.references :sutra, null: false, foreign_key: true
      t.integer :number, null: false          # 파일의 phrases[].id
      t.string :han, null: false
      t.string :ko, null: false
      t.string :en, null: false
      t.integer :start_pos, null: false       # 파일의 start
      t.integer :end_pos, null: false         # 파일의 end

      t.timestamps
    end
    add_index :sutra_phrases, [ :sutra_id, :number ], unique: true

    create_table :sutra_chars do |t|
      t.references :sutra, null: false, foreign_key: true
      t.references :sutra_phrase, null: false, foreign_key: true
      t.integer :pos, null: false
      t.string :glyph, null: false
      t.string :reading, null: false
      t.string :sense_here, null: false
      t.string :gloss_en, null: false
      t.integer :nth, null: false
      t.integer :total, null: false
      t.json :sanskrit                        # 음역자만: word · syllable · sound_ko

      t.timestamps
    end
    add_index :sutra_chars, [ :sutra_id, :pos ], unique: true
  end
end

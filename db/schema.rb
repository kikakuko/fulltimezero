# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_17_120000) do
  create_table "abidings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "engagement", null: false
    t.string "engagement_en", null: false
    t.string "gloss_en", null: false
    t.string "han", null: false
    t.string "hindrance", null: false
    t.string "hindrance_en", null: false
    t.text "image", null: false
    t.text "image_en", null: false
    t.string "ko", null: false
    t.string "one_line", null: false
    t.string "one_line_en", null: false
    t.integer "pos", null: false
    t.string "power", null: false
    t.string "power_en", null: false
    t.string "sanskrit", null: false
    t.string "sit_hint", null: false
    t.string "sit_hint_en", null: false
    t.datetime "updated_at", null: false
    t.text "what_happens", null: false
    t.text "what_happens_en", null: false
    t.text "what_to_do", null: false
    t.text "what_to_do_en", null: false
    t.index ["pos"], name: "index_abidings_on_pos", unique: true
  end

  create_table "clearings", force: :cascade do |t|
    t.date "cleared_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "cleared_on"], name: "index_clearings_on_user_id_and_cleared_on", unique: true
    t.index ["user_id"], name: "index_clearings_on_user_id"
  end

  create_table "copyings", force: :cascade do |t|
    t.date "copied_on", null: false
    t.datetime "created_at", null: false
    t.json "glyph_paths", null: false
    t.integer "sutra_char_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["sutra_char_id"], name: "index_copyings_on_sutra_char_id"
    t.index ["user_id", "copied_on"], name: "index_copyings_on_user_id_and_copied_on", unique: true
    t.index ["user_id", "sutra_char_id"], name: "index_copyings_on_user_id_and_sutra_char_id", unique: true
    t.index ["user_id"], name: "index_copyings_on_user_id"
  end

  create_table "plans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "planned_on", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "what", null: false
    t.index ["user_id", "planned_on"], name: "index_plans_on_user_id_and_planned_on"
    t.index ["user_id"], name: "index_plans_on_user_id"
  end

  create_table "rests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "duration", null: false
    t.text "note"
    t.date "rested_on", null: false
    t.string "texture"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "rested_on"], name: "index_rests_on_user_id_and_rested_on"
    t.index ["user_id"], name: "index_rests_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sittings", force: :cascade do |t|
    t.integer "abiding_id"
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.string "mode", null: false
    t.date "sat_on", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["abiding_id"], name: "index_sittings_on_abiding_id"
    t.index ["user_id", "sat_on"], name: "index_sittings_on_user_id_and_sat_on"
    t.index ["user_id"], name: "index_sittings_on_user_id"
  end

  create_table "sutra_chars", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "gloss_en", null: false
    t.string "glyph", null: false
    t.integer "nth", null: false
    t.integer "pos", null: false
    t.string "reading", null: false
    t.json "sanskrit"
    t.string "sense_here", null: false
    t.integer "sutra_id", null: false
    t.integer "sutra_phrase_id", null: false
    t.integer "total", null: false
    t.datetime "updated_at", null: false
    t.index ["sutra_id", "pos"], name: "index_sutra_chars_on_sutra_id_and_pos", unique: true
    t.index ["sutra_id"], name: "index_sutra_chars_on_sutra_id"
    t.index ["sutra_phrase_id"], name: "index_sutra_chars_on_sutra_phrase_id"
  end

  create_table "sutra_phrases", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "en", null: false
    t.integer "end_pos", null: false
    t.string "han", null: false
    t.string "ko", null: false
    t.integer "number", null: false
    t.integer "start_pos", null: false
    t.integer "sutra_id", null: false
    t.datetime "updated_at", null: false
    t.index ["sutra_id", "number"], name: "index_sutra_phrases_on_sutra_id_and_number", unique: true
    t.index ["sutra_id"], name: "index_sutra_phrases_on_sutra_id"
  end

  create_table "sutras", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "edition"
    t.string "slug", null: false
    t.string "title_han", null: false
    t.string "title_ko", null: false
    t.integer "total", null: false
    t.text "translation_note"
    t.integer "unique_glyphs"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_sutras_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "clearing_sound", default: false, null: false
    t.datetime "created_at", null: false
    t.boolean "daily_door", default: true, null: false
    t.string "email_address", null: false
    t.string "locale", default: "ko", null: false
    t.date "maitreya_seen_on"
    t.datetime "onboarded_at"
    t.string "password_digest", null: false
    t.string "time_zone", default: "Asia/Seoul", null: false
    t.datetime "updated_at", null: false
    t.text "what_moves"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "clearings", "users"
  add_foreign_key "copyings", "sutra_chars"
  add_foreign_key "copyings", "users"
  add_foreign_key "plans", "users"
  add_foreign_key "rests", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "sittings", "abidings"
  add_foreign_key "sittings", "users"
  add_foreign_key "sutra_chars", "sutra_phrases"
  add_foreign_key "sutra_chars", "sutras"
  add_foreign_key "sutra_phrases", "sutras"
end

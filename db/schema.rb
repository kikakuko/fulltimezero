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

ActiveRecord::Schema[8.1].define(version: 2026_08_27_130000) do
  create_table "clearings", force: :cascade do |t|
    t.date "cleared_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "cleared_on"], name: "index_clearings_on_user_id_and_cleared_on", unique: true
    t.index ["user_id"], name: "index_clearings_on_user_id"
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
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sittings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.string "mode", null: false
    t.date "sat_on", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "sat_on"], name: "index_sittings_on_user_id_and_sat_on"
    t.index ["user_id"], name: "index_sittings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "locale", default: "ko", null: false
    t.string "password_digest", null: false
    t.string "time_zone", default: "Asia/Seoul", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "clearings", "users"
  add_foreign_key "plans", "users"
  add_foreign_key "rests", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "sittings", "users"
end

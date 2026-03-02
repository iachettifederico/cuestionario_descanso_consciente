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

ActiveRecord::Schema[8.0].define(version: 2026_03_02_225342) do
  create_table "categories", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.string "identifier", limit: 50, null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier"], name: "index_categories_on_identifier", unique: true
    t.index ["position"], name: "index_categories_on_position"
  end

  create_table "diary_entries", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "day_number", null: false
    t.date "fecha"
    t.string "palabra"
    t.text "ratings", default: "{}"
    t.string "hora_dormir"
    t.decimal "horas_dormidas", precision: 4, scale: 1
    t.string "calidad_sueno"
    t.string "tipo_alto"
    t.text "sensacion"
    t.text "reflexion"
    t.text "micropausa"
    t.text "reflexion_final"
    t.string "pausa_estrella"
    t.string "proximo_foco"
    t.text "rutina"
    t.boolean "saved", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "day_number"], name: "index_diary_entries_on_user_id_and_day_number", unique: true
    t.index ["user_id"], name: "index_diary_entries_on_user_id"
  end

  create_table "questions", force: :cascade do |t|
    t.text "text", null: false
    t.integer "category_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_questions_on_category_id"
    t.index ["position"], name: "index_questions_on_position"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", default: "", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "diary_entries", "users"
  add_foreign_key "questions", "categories"
  add_foreign_key "sessions", "users"
end

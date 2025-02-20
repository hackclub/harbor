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

ActiveRecord::Schema[8.0].define(version: 2025_02_16_173459) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "leaderboard_entries", force: :cascade do |t|
    t.bigint "leaderboard_id", null: false
    t.string "user_id", null: false
    t.integer "total_seconds", default: 0, null: false
    t.integer "rank"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["leaderboard_id", "user_id"], name: "idx_leaderboard_entries_on_leaderboard_and_user", unique: true
    t.index ["leaderboard_id"], name: "index_leaderboard_entries_on_leaderboard_id"
  end

  create_table "leaderboards", force: :cascade do |t|
    t.date "start_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["start_date"], name: "index_leaderboards_on_start_date", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "slack_uid", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.string "avatar_url"
    t.boolean "is_admin", default: false, null: false
    t.index ["slack_uid"], name: "index_users_on_slack_uid", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "leaderboard_entries", "leaderboards"
end

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

ActiveRecord::Schema[8.0].define(version: 2025_03_05_195904) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_keys", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "name", null: false
    t.text "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_api_keys_on_token", unique: true
    t.index ["user_id", "name"], name: "index_api_keys_on_user_id_and_name", unique: true
    t.index ["user_id", "token"], name: "index_api_keys_on_user_id_and_token", unique: true
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
    t.datetime "jobs_finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.text "error_backtrace", array: true
    t.uuid "process_id"
    t.interval "duration"
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
    t.integer "lock_type", limit: 2
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.uuid "locked_by_id"
    t.datetime "locked_at"
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "heartbeats", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "branch"
    t.string "category"
    t.string "dependencies", default: [], array: true
    t.string "editor"
    t.string "entity"
    t.string "language"
    t.string "machine"
    t.string "operating_system"
    t.string "project"
    t.string "type"
    t.string "user_agent"
    t.integer "line_additions"
    t.integer "line_deletions"
    t.integer "lineno"
    t.integer "lines"
    t.integer "cursorpos"
    t.integer "project_root_count"
    t.float "time", null: false
    t.boolean "is_write"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "fields_hash"
    t.integer "source_type", default: 0, null: false
    t.index ["fields_hash"], name: "index_heartbeats_on_fields_hash", unique: true
    t.index ["user_id"], name: "index_heartbeats_on_user_id"
  end

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
    t.datetime "finished_generating_at"
    t.datetime "deleted_at"
  end

  create_table "project_checks", force: :cascade do |t|
    t.integer "check_type"
    t.integer "status"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.text "output_message"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["check_type", "created_at"], name: "index_project_checks_on_check_type_and_created_at"
    t.index ["status"], name: "index_project_checks_on_status"
  end

  create_table "sailors_log_leaderboards", force: :cascade do |t|
    t.string "slack_channel_id"
    t.string "slack_uid"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
  end

  create_table "sailors_log_notification_preferences", force: :cascade do |t|
    t.string "slack_uid", null: false
    t.string "slack_channel_id", null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slack_uid", "slack_channel_id"], name: "idx_sailors_log_notification_preferences_unique_user_channel", unique: true
  end

  create_table "sailors_log_slack_notifications", force: :cascade do |t|
    t.string "slack_uid", null: false
    t.string "slack_channel_id", null: false
    t.string "project_name", null: false
    t.integer "project_duration", null: false
    t.boolean "sent", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sailors_logs", force: :cascade do |t|
    t.string "slack_uid", null: false
    t.jsonb "projects_summary", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ship_chains", force: :cascade do |t|
    t.text "code_url"
    t.text "demo_url"
    t.text "readme_url"
    t.text "description"
    t.integer "ysws_type"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code_url"], name: "index_ship_chains_on_code_url"
    t.index ["demo_url"], name: "index_ship_chains_on_demo_url"
    t.index ["user_id"], name: "index_ship_chains_on_user_id"
  end

  create_table "ship_update_descriptions", force: :cascade do |t|
    t.string "what_changed"
    t.bigint "ship_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ship_id"], name: "index_ship_update_descriptions_on_ship_id"
  end

  create_table "ships", force: :cascade do |t|
    t.bigint "ship_chain_id", null: false
    t.integer "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ship_chain_id"], name: "index_ships_on_ship_chain_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "slack_uid", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.string "avatar_url"
    t.boolean "is_admin", default: false, null: false
    t.boolean "uses_slack_status", default: false, null: false
    t.string "slack_scopes", default: [], array: true
    t.text "slack_access_token"
    t.integer "hackatime_extension_text_type", default: 0, null: false
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

  add_foreign_key "api_keys", "users"
  add_foreign_key "heartbeats", "users"
  add_foreign_key "leaderboard_entries", "leaderboards"
  add_foreign_key "ship_chains", "users"
  add_foreign_key "ship_update_descriptions", "ships"
  add_foreign_key "ships", "ship_chains"
end

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

ActiveRecord::Schema[8.0].define(version: 2025_05_07_161052) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activities", force: :cascade do |t|
    t.string "trackable_type"
    t.bigint "trackable_id"
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "key"
    t.text "parameters"
    t.string "recipient_type"
    t.bigint "recipient_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type"
    t.index ["owner_type", "owner_id"], name: "index_activities_on_owner"
    t.index ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type"
    t.index ["recipient_type", "recipient_id"], name: "index_activities_on_recipient"
    t.index ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type"
    t.index ["trackable_type", "trackable_id"], name: "index_activities_on_trackable"
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.bigint "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.bigint "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.string "app_version"
    t.string "os_version"
    t.string "platform"
    t.datetime "started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

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

  create_table "email_addresses", force: :cascade do |t|
    t.string "email"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "source"
    t.index ["email"], name: "index_email_addresses_on_email", unique: true
    t.index ["user_id"], name: "index_email_addresses_on_user_id"
  end

  create_table "email_verification_requests", force: :cascade do |t|
    t.string "email"
    t.bigint "user_id", null: false
    t.string "token"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["email"], name: "index_email_verification_requests_on_email", unique: true
    t.index ["user_id"], name: "index_email_verification_requests_on_user_id"
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
    t.integer "source_type", null: false
    t.inet "ip_address"
    t.integer "ysws_program", default: 0, null: false
    t.index ["category", "time"], name: "index_heartbeats_on_category_and_time"
    t.index ["fields_hash"], name: "index_heartbeats_on_fields_hash", unique: true
    t.index ["user_id"], name: "index_heartbeats_on_user_id"
  end

  create_table "leaderboard_entries", force: :cascade do |t|
    t.bigint "leaderboard_id", null: false
    t.integer "total_seconds", default: 0, null: false
    t.integer "rank"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "streak_count", default: 0
    t.index ["leaderboard_id", "user_id"], name: "idx_leaderboard_entries_on_leaderboard_and_user", unique: true
    t.index ["leaderboard_id"], name: "index_leaderboard_entries_on_leaderboard_id"
  end

  create_table "leaderboards", force: :cascade do |t|
    t.date "start_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "finished_generating_at"
    t.datetime "deleted_at"
    t.integer "period_type", default: 0, null: false
  end

  create_table "project_repo_mappings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "project_name", null: false
    t.string "repo_url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "project_name"], name: "index_project_repo_mappings_on_user_id_and_project_name", unique: true
    t.index ["user_id"], name: "index_project_repo_mappings_on_user_id"
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

  create_table "sign_in_tokens", force: :cascade do |t|
    t.string "token"
    t.bigint "user_id", null: false
    t.integer "auth_type"
    t.datetime "expires_at"
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_sign_in_tokens_on_token"
    t.index ["user_id"], name: "index_sign_in_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "slack_uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.string "slack_avatar_url"
    t.boolean "is_admin", default: false, null: false
    t.boolean "uses_slack_status", default: false, null: false
    t.string "slack_scopes", default: [], array: true
    t.text "slack_access_token"
    t.integer "hackatime_extension_text_type", default: 0, null: false
    t.string "timezone", default: "UTC"
    t.string "github_uid"
    t.string "github_avatar_url"
    t.text "github_access_token"
    t.string "github_username"
    t.string "slack_username"
    t.string "slack_neighborhood_channel"
    t.index ["slack_uid"], name: "index_users_on_slack_uid", unique: true
    t.index ["timezone"], name: "index_users_on_timezone"
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
  add_foreign_key "email_addresses", "users"
  add_foreign_key "email_verification_requests", "users"
  add_foreign_key "heartbeats", "users"
  add_foreign_key "leaderboard_entries", "leaderboards"
  add_foreign_key "leaderboard_entries", "users"
  add_foreign_key "project_repo_mappings", "users"
  add_foreign_key "sign_in_tokens", "users"
end

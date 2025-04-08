class Cache::ActiveProjectsJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  # Limits concurrency to 1 job per date
  good_job_control_concurrency_with(
    total: 1,
    drop: true
  )

  def perform(force_reload: false)
    key = "active_projects"
    expiration = 15.minutes
    Rails.cache.write(key, calculate, expires_in: expiration) if force_reload

    Rails.cache.fetch(key, expires_in: expiration,) do
      calculate
    end
  end

  private

  def calculate
    # Get recent heartbeats with matching project_repo_mappings in a single SQL query
    ProjectRepoMapping.joins("INNER JOIN heartbeats ON heartbeats.project = project_repo_mappings.project_name")
                      .joins("INNER JOIN users ON users.id = heartbeats.user_id")
                      .where("heartbeats.source_type = ?", Heartbeat.source_types[:direct_entry])
                      .where("heartbeats.time > ?", 5.minutes.ago.to_f)
                      .select("DISTINCT ON (heartbeats.user_id) project_repo_mappings.*, heartbeats.user_id")
                      .order("heartbeats.user_id, heartbeats.time DESC")
                      .index_by(&:user_id)
  end
end

class Cache::CurrentlyHackingJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  # Limits concurrency to 1 job per date
  good_job_control_concurrency_with(
    total: 1,
    drop: true
  )

  def perform(force_reload: false)
    key = "currently_hacking"
    expiration = 1.minute
    Rails.cache.write(key, calculate, expires_in: expiration) if force_reload

    Rails.cache.fetch(key, expires_in: expiration) do
      calculate
    end
  end

  private

  def calculate
    # Get most recent heartbeats and users in a single query
    recent_heartbeats = Heartbeat.joins(:user)
                                .where(source_type: :direct_entry)
                                .coding_only
                                .where("time > ?", 5.minutes.ago.to_f)
                                .select("DISTINCT ON (user_id) user_id, project, time, users.*")
                                .order("user_id, time DESC")
                                .includes(:user => :project_repo_mappings)
                                .index_by(&:user_id)

    users = recent_heartbeats.values.map(&:user)

    active_projects = {}
    users.each do |user|
      recent_heartbeat = recent_heartbeats[user.id]
      active_projects[user.id] = user.project_repo_mappings.find { |p| p.project_name == recent_heartbeat&.project }
    end

    users = users.sort_by do |user|
      [
        active_projects[user.id].present? ? 0 : 1,
        user.username.present? ? 0 : 1,
        user.slack_username.present? ? 0 : 1,
        user.github_username.present? ? 0 : 1
      ]
    end

    { users: users, active_projects: active_projects }
  end
end

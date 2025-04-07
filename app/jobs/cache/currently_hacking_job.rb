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
    # Get all users who have heartbeats in the last 15 minutes
    user_ids = Heartbeat.where("time > ?", 5.minutes.ago.to_f)
                        .coding_only
                        .distinct
                        .pluck(:user_id)

    users = User.where(id: user_ids).includes(:project_repo_mappings)

    active_projects = {}
    users.each do |user|
      active_projects[user.id] = user.project_repo_mappings.find { |p| p.project_name == user.active_project }
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

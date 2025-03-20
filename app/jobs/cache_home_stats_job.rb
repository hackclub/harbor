class CacheHomeStatsJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  # Limits concurrency to 1 job per date
  good_job_control_concurrency_with(
    total: 1,
    drop: true
  )

  def perform
    seconds_by_user = Heartbeat.group(:user_id).duration_seconds
    home_stats = {
      users_tracked: seconds_by_user.size,
      seconds_tracked: seconds_by_user.values.sum
    }
    Rails.cache.write("home_stats", home_stats, expires_in: 1.hour)
    home_stats
  end
end

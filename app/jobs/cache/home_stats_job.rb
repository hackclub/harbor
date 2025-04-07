class Cache::HomeStatsJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  # Limits concurrency to 1 job per date
  good_job_control_concurrency_with(
    total: 1,
    drop: true
  )

  def perform(force_reload: false)
    key = "home_stats"
    expiration = 1.hour
    Rails.cache.write(key, calculate, expires_in: expiration) if force_reload

    Rails.cache.fetch(key, expires_in: expiration, ) do
      calculate
    end
  end

  private

  def calculate
    seconds_by_user = Heartbeat.group(:user_id).duration_seconds
    {
      users_tracked: seconds_by_user.size,
      seconds_tracked: seconds_by_user.values.sum
    }
  end
end
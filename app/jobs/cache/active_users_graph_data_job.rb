class Cache::ActiveUsersGraphDataJob < ApplicationJob
  # TODO: create concern for these cache jobs– make it single enqueue
  include GoodJob::ActiveJobExtensions::Concurrency

  # Limits concurrency to 1 job per date
  good_job_control_concurrency_with(
    total: 1,
    drop: true
  )

  def perform(force_reload: false)
    key = "cache:active_users_graph_data"
    expiration = 1.hour
    Rails.cache.write(key, calculate, expires_in: expiration) if force_reload

    Rails.cache.fetch(key, expires_in: expiration) do
      calculate
    end
  end

  private

  def calculate
    # over the last 24 hours, count the number of people who were active each hour
    hours = Heartbeat.coding_only
                     .with_valid_timestamps
                     .where("time > ?", 24.hours.ago.to_f)
                     .select("(EXTRACT(EPOCH FROM to_timestamp(time))::bigint / 3600 * 3600) as hour, COUNT(DISTINCT user_id) as count")
                     .group("hour")
                     .order("hour DESC")

    top_hour_count = hours.max_by(&:count)&.count || 1

    hours = hours.map do |h|
      {
        hour: Time.at(h.hour),
        users: h.count,
        height: (h.count.to_f / top_hour_count * 100).round
      }
    end
  end
end
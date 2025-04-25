class LeaderboardUpdateJob < ApplicationJob
  queue_as :default
  BATCH_SIZE = 1000

  include GoodJob::ActiveJobExtensions::Concurrency

  # Limits concurrency to 1 job per date
  good_job_control_concurrency_with(
    key: -> { "#{arguments[0] || 'daily'}_#{arguments[1] || Date.current.to_s}" },
    total: 1,
    drop: true
  )

  def perform(period_type = :daily, date = Date.current)
    parsed_date = date.is_a?(Date) ? date : Date.parse(date.to_s)

    parsed_date = parsed_date.beginning_of_week if period_type == :weekly

    leaderboard = Leaderboard.create!(
      start_date: parsed_date,
      period_type: period_type
    )

    date_range = case period_type
    when :weekly
      (parsed_date.beginning_of_day...(parsed_date + 7.days).beginning_of_day)
    when :last_7_days
      ((parsed_date - 6.days).beginning_of_day...parsed_date.end_of_day)
    else
      parsed_date.all_day
    end

    Rails.logger.info "Starting leaderboard generation for #{period_type} on #{parsed_date}"

    ActiveRecord::Base.transaction do
      entries_data = Heartbeat.where(time: date_range)
                              .coding_only
                              .with_valid_timestamps
                              .group(:user_id)
                              .duration_seconds

      entries_data = entries_data.filter { |_, total_seconds| total_seconds > 60 }.sort_by { |_, total_seconds| -total_seconds }

      streaks = Heartbeat.daily_streaks_for_users(entries_data.map { |user_id, _| user_id })

      entries_data = entries_data.map.with_index(1) do |(user_id, total_seconds), index|
        {
          leaderboard_id: leaderboard.id,
          user_id: user_id,
          total_seconds: total_seconds,
          streak_count: streaks[user_id] || 0,
          rank: index
        }
      end

      LeaderboardEntry.insert_all!(entries_data) if entries_data.any?
    end

    leaderboard.finished_generating_at = Time.current
    leaderboard.save!

    Leaderboard.where.not(id: leaderboard.id)
               .where(start_date: parsed_date, period_type: period_type)
               .where(deleted_at: nil)
               .update_all(deleted_at: Time.current)

    leaderboard
  rescue => e
    Rails.logger.error "Failed to update current leaderboard: #{e.message}"
    raise
  rescue Date::Error
    raise ArgumentError, "Invalid date format provided"
  end
end

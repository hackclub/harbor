module Heartbeatable
  extend ActiveSupport::Concern

  included do
    # Filter heartbeats to only include those with category equal to "coding"
    scope :coding_only, -> { where(category: "coding") }

    # This is to prevent PG timestamp overflow errors if someones gives us a
    # heartbeat with a time that is enormously far in the future.
    scope :with_valid_timestamps, -> { where("time >= 0 AND time <= ?", 253402300799) }
  end

  class_methods do
    def heartbeat_timeout_duration(duration = nil)
      if duration
        @heartbeat_timeout_duration = duration
      else
        @heartbeat_timeout_duration || 2.minutes
      end
    end

    def streak_days(start_date: 8.days.ago)
      scope = coding_only.with_valid_timestamps
      days = scope.daily_durations(start_date: start_date, end_date: Time.current)
                .sort_by { |date, _| date }
                .reverse

      streak = 0
      days.each do |date, duration|
        if duration >= 15 * 60
          streak += 1
        else
          break
        end
      end

      streak
    end

    def duration_formatted(scope = all)
      seconds = duration_seconds(scope)
      hours = seconds / 3600
      minutes = (seconds % 3600) / 60
      remaining_seconds = seconds % 60

      format("%02d:%02d:%02d", hours, minutes, remaining_seconds)
    end

    def duration_simple(scope = all)
      # 3 hours 10 min => "3 hrs"
      # 1 hour 10 min => "1 hr"
      # 10 min => "10 min"
      seconds = duration_seconds(scope)
      hours = seconds / 3600
      minutes = (seconds % 3600) / 60

      if hours > 1
        "#{hours} hrs"
      elsif hours == 1
        "1 hr"
      elsif minutes > 0
        "#{minutes} min"
      else
        "0 min"
      end
    end

    def daily_durations(start_date: 365.days.ago, end_date: Time.current)
      # Get the timezone from the first associated user (for scoped queries)
      timezone = all.first&.user&.timezone || "UTC"

      # Create the timezone-aware date truncation expression
      day_trunc = Arel.sql("DATE_TRUNC('day', to_timestamp(time) AT TIME ZONE '#{timezone}')")

      select(day_trunc.as("day_group"))
        .coding_only
        .where(time: start_date..end_date)
        .with_valid_timestamps
        .group(day_trunc)
        .duration_seconds
        .map { |date, duration| [ date.to_date, duration ] }
    end

    def duration_seconds(scope = all)
      scope = scope.coding_only.with_valid_timestamps

      if scope.group_values.any?
        group_column = scope.group_values.first

        # Don't quote if it's a SQL function (contains parentheses)
        group_expr = group_column.to_s.include?("(") ? group_column : connection.quote_column_name(group_column)

        capped_diffs = scope
          .select("#{group_expr} as grouped_time, CASE
            WHEN LAG(time) OVER (PARTITION BY #{group_expr} ORDER BY time) IS NULL THEN 0
            ELSE LEAST(EXTRACT(EPOCH FROM (to_timestamp(time) - to_timestamp(LAG(time) OVER (PARTITION BY #{group_expr} ORDER BY time)))), #{heartbeat_timeout_duration.to_i})
          END as diff")
          .where.not(time: nil)
          .order(time: :asc)
          .unscope(:group)

        connection.select_all(
          "SELECT grouped_time, COALESCE(SUM(diff), 0)::integer as duration
          FROM (#{capped_diffs.to_sql}) AS diffs
          GROUP BY grouped_time"
        ).each_with_object({}) do |row, hash|
          hash[row["grouped_time"]] = row["duration"].to_i
        end
      else
        # when not grouped, return a single value
        capped_diffs = scope
          .select("CASE
            WHEN LAG(time) OVER (ORDER BY time) IS NULL THEN 0
            ELSE LEAST(EXTRACT(EPOCH FROM (to_timestamp(time) - to_timestamp(LAG(time) OVER (ORDER BY time)))), #{heartbeat_timeout_duration.to_i})
          END as diff")
          .where.not(time: nil)
          .order(time: :asc)

        connection.select_value("SELECT COALESCE(SUM(diff), 0)::integer FROM (#{capped_diffs.to_sql}) AS diffs").to_i
      end
    end
  end
end

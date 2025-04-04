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

    def streak_days_formatted(start_date: 8.days.ago)
      result = streak_days(start_date: start_date)

      if result > 7
        "7+"
      elsif result < 1
        nil
      else
        result.to_s
      end
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

    def daily_streaks_for_users(user_ids, start_date: 8.days.ago)
      # First get the raw durations using window function
      raw_durations = joins(:user)
        .where(user_id: user_ids)
        .coding_only
        .with_valid_timestamps
        .where(time: start_date..Time.current)
        .select(
          :user_id,
          "users.timezone as user_timezone",
          Arel.sql("DATE_TRUNC('day', to_timestamp(time) AT TIME ZONE users.timezone) as day_group"),
          Arel.sql("LEAST(EXTRACT(EPOCH FROM (to_timestamp(time) - to_timestamp(LAG(time) OVER (PARTITION BY user_id, DATE_TRUNC('day', to_timestamp(time) AT TIME ZONE users.timezone) ORDER BY time)))), #{heartbeat_timeout_duration.to_i}) as diff")
        )

      # Then aggregate the results
      daily_durations = connection.select_all(
        "SELECT user_id, user_timezone, day_group, COALESCE(SUM(diff), 0)::integer as duration
         FROM (#{raw_durations.to_sql}) AS diffs
         GROUP BY user_id, user_timezone, day_group"
      ).group_by { |row| row["user_id"] }
       .transform_values do |rows|
         timezone = rows.first["user_timezone"]
         current_date = Time.current.in_time_zone(timezone).to_date
         {
           current_date: current_date,
           days: rows.map do |row|
             [ row["day_group"].to_date, row["duration"].to_i ]
           end.sort_by { |date, _| date }.reverse
         }
       end

      # Initialize the result hash with zeros for all users
      result = user_ids.index_with { 0 }

      # Then calculate streaks for each user
      daily_durations.each do |user_id, data|
        current_date = data[:current_date]
        days = data[:days]

        # Calculate streak
        streak = 0
        days.each do |date, duration|
          # Skip if this day is in the future
          next if date > current_date

          # If they didn't code enough today, just skip
          if date == current_date
            next unless duration >= 15 * 60
            streak += 1
            next
          end

          # For previous days, check if it's the next day in the streak
          if date == current_date - streak.days && duration >= 15 * 60
            streak += 1
          else
            break
          end
        end

        result[user_id] = streak
      end

      result
    end

    def daily_durations(start_date: 365.days.ago, end_date: Time.current)
      # Get the timezone from the first associated user (for scoped queries)
      timezone = all.first&.user&.timezone || "UTC"

      # Create the timezone-aware date truncation expression
      day_trunc = Arel.sql("DATE_TRUNC('day', to_timestamp(time) AT TIME ZONE '#{timezone}')")

      select(day_trunc.as("day_group"))
        .where(time: start_date..end_date)
        .group(day_trunc)
        .duration_seconds
        .map { |date, duration| [ date.to_date, duration ] }
    end

    def duration_seconds(scope = all)
      scope = scope.with_valid_timestamps

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

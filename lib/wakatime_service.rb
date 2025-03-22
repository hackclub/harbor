include ApplicationHelper

class WakatimeService
  def initialize(user = nil, specific_filters = {}, allow_cache = true)
    @scope = Heartbeat.all
    @user = user

    @scope = @scope.where(user_id: @user.id) if @user.present?

    @specific_filters = specific_filters
    @allow_cache = allow_cache
  end

  def generate_summary
    summary = {}

    summary[:username] = @user.username if @user.present?
    summary[:user_id] = @user.id.to_s if @user.present?
    summary[:is_coding_activity_visible] = true if @user.present?
    summary[:is_other_usage_visible] = true if @user.present?
    summary[:status] = "ok"

    @start_time = @scope.minimum(:time)
    @end_time = @scope.maximum(:time)
    summary[:start] = Time.at(@start_time).strftime("%Y-%m-%dT%H:%M:%SZ")
    summary[:end] = Time.at(@end_time).strftime("%Y-%m-%dT%H:%M:%SZ")

    summary[:range] = "all_time"
    summary[:human_readable_range] = "All Time"

    @total_seconds = @scope.duration_seconds
    summary[:total_seconds] = @total_seconds

    @total_days = (@end_time - @start_time) / 86400
    summary[:daily_average] = @total_seconds / @total_days

    summary[:human_readable_total] = ApplicationController.helpers.short_time_detailed(@total_seconds)
    summary[:human_readable_daily_average] = ApplicationController.helpers.short_time_detailed(summary[:daily_average])

    summary[:languages] = generate_summary_chunk(:language) if @specific_filters[:languages]
    summary[:projects] = generate_summary_chunk(:project) if @specific_filters[:projects]

    summary
  end

  def generate_summary_chunk(group_by)
    result = []
    @scope.group(group_by).duration_seconds.each do |key, value|
      normalized_name = if group_by == :editor
        NameNormalizerService.normalize_editor(key)
      elsif group_by == :operating_system
        NameNormalizerService.normalize_os(key)
      else
        key.presence || "Other"
      end

      result << {
        name: normalized_name,
        total_seconds: value,
        text: ApplicationController.helpers.short_time_simple(value),
        hours: value / 3600,
        minutes: (value % 3600) / 60,
        percent: (100.0 * value / @total_seconds).round(2),
        digital: ApplicationController.helpers.digital_time(value)
      }
    end
    result.sort_by { |item| -item[:total_seconds] }.first(10)
  end
end

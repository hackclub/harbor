module Api
  class SummaryController < ApplicationController
    skip_before_action :verify_authenticity_token

    def index
      # Parse interval or date range
      date_range = determine_date_range(params[:interval], params[:from], params[:to])
      return render json: { error: "Invalid date range" }, status: :bad_request unless date_range

      # Get heartbeats for all users unless filtered
      heartbeats = Heartbeat.all.where(created_at: date_range)

      # Apply filters if provided
      heartbeats = filter_heartbeats(heartbeats, params)

      # Calculate summary
      summary = calculate_summary(heartbeats, date_range)

      render json: summary
    end

    private

    def determine_date_range(interval, from_date, to_date)
      timezone = "UTC"
      Time.use_zone(timezone) do
        now = Time.current

        if from_date.present? && to_date.present?
          begin
            from = Time.zone.parse(from_date).beginning_of_day
            to = Time.zone.parse(to_date).end_of_day
            return from..to
          rescue
            return nil
          end
        end

        case interval
        when "today"
          now.beginning_of_day..now.end_of_day
        when "yesterday"
          (now - 1.day).beginning_of_day..(now - 1.day).end_of_day
        when "week", "7_days"
          now.beginning_of_week..now.end_of_week
        when "last_7_days"
          (now - 7.days).beginning_of_day..now.end_of_day
        when "month", "30_days"
          now.beginning_of_month..now.end_of_month
        when "last_30_days"
          (now - 30.days).beginning_of_day..now.end_of_day
        when "6_months"
          now.beginning_of_month - 5.months..now.end_of_month
        when "last_6_months"
          (now - 6.months).beginning_of_day..now.end_of_day
        when "year", "12_months"
          now.beginning_of_year..now.end_of_year
        when "last_12_months", "last_year"
          (now - 1.year).beginning_of_day..now.end_of_day
        when "any", "all_time", nil
          Time.at(0)..now.end_of_day
        when "low_skies", "high_seas"  # Custom intervals in the spec
          now.beginning_of_month..now.end_of_month
        else
          now.beginning_of_day..now.end_of_day # Default to today
        end
      end
    end

    def filter_heartbeats(heartbeats, params)
      heartbeats = heartbeats.where(project: params[:project]) if params[:project].present?
      heartbeats = heartbeats.where(language: params[:language]) if params[:language].present?
      heartbeats = heartbeats.where(editor: params[:editor]) if params[:editor].present?
      heartbeats = heartbeats.where(operating_system: params[:operating_system]) if params[:operating_system].present?
      heartbeats = heartbeats.where(machine: params[:machine]) if params[:machine].present?
      heartbeats = heartbeats.where(user_id: params[:user]) if params[:user].present?

      heartbeats
    end

    def calculate_summary(heartbeats, date_range)
      projects = {}
      languages = {}
      editors = {}
      operating_systems = {}
      machines = {}
      categories = {}
      branches = {}
      entities = {}
      labels = {}

      heartbeats.find_each do |heartbeat|
        # For each category, add the heartbeat's duration to the appropriate key
        # Assuming each heartbeat represents a time unit
        projects[heartbeat.project] ||= 0
        projects[heartbeat.project] += 1

        languages[heartbeat.language] ||= 0
        languages[heartbeat.language] += 1 if heartbeat.language.present?

        editors[heartbeat.editor] ||= 0
        editors[heartbeat.editor] += 1 if heartbeat.editor.present?

        operating_systems[heartbeat.operating_system] ||= 0
        operating_systems[heartbeat.operating_system] += 1 if heartbeat.operating_system.present?

        machines[heartbeat.machine] ||= 0
        machines[heartbeat.machine] += 1 if heartbeat.machine.present?

        categories[heartbeat.category] ||= 0
        categories[heartbeat.category] += 1 if heartbeat.category.present?

        branches[heartbeat.branch] ||= 0
        branches[heartbeat.branch] += 1 if heartbeat.branch.present?

        entities[heartbeat.entity] ||= 0
        entities[heartbeat.entity] += 1 if heartbeat.entity.present?
      end

      # Format summary items
      {
        from: date_range.begin.strftime('%Y-%m-%d %H:%M:%S.000'),
        to: date_range.end.strftime('%Y-%m-%d %H:%M:%S.000'),
        projects: format_summary_items(projects),
        languages: format_summary_items(languages),
        editors: format_summary_items(editors),
        operating_systems: format_summary_items(operating_systems),
        machines: format_summary_items(machines),
        categories: format_summary_items(categories),
        branches: format_summary_items(branches),
        entities: format_summary_items(entities),
        labels: format_summary_items(labels)
      }
    end

    def format_summary_items(items_hash)
      items_hash.map do |key, total|
        next if key.blank?
        {
          key: key,
          total: total
        }
      end.compact
    end
  end
end

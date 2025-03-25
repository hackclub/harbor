class UsersController < ApplicationController
  include ActionView::Helpers::NumberHelper

  before_action :set_user
  before_action :require_current_user
  before_action :require_admin, unless: :is_own_settings?

  def edit
    @can_enable_slack_status = @user.slack_access_token.present? && @user.slack_scopes.include?("users.profile:write")

    @enabled_sailors_logs = SailorsLogNotificationPreference.where(
      slack_uid: @user.slack_uid,
      enabled: true,
    ).where.not(slack_channel_id: "C0835AZP9GB")

    @heartbeats_migration_jobs = @user.data_migration_jobs
  end

  def update
    if @user.update(user_params)
      if @user.uses_slack_status?
        @user.update_slack_status
      end
      redirect_to is_own_settings? ? my_settings_path : user_settings_path(@user),
        notice: "Settings updated successfully"
    else
      flash[:error] = "Failed to update settings"
      render :settings, status: :unprocessable_entity
    end
  end

  def migrate_heartbeats
    OneTime::MigrateUserFromHackatimeJob.perform_later(@user.id)

    redirect_to is_own_settings? ? my_settings_path : user_settings_path(@user),
      notice: "Heartbeats & api keys migration started"
  end

  def wakatime_setup
    api_key = current_user&.api_keys&.last
    api_key ||= current_user.api_keys.create!(name: "Wakatime API Key")
    @current_user_api_key = api_key&.token
  end

  def wakatime_setup_step_2
  end

  def wakatime_setup_step_3
  end

  def wakatime_setup_step_4
    @no_instruction_wording = [
      "There is no step 4, lol.",
      "There is no step 4, psych!",
      "Tricked ya! There is no step 4.",
      "There is no step 4, gotcha!"
    ].sample
  end

  def show
    # Use current_user for /my/home route, otherwise find by id
    @user = if params[:id].present?
      User.find(params[:id])
    else
      current_user
    end
  end

  def filterable_dashboard_content
    @user = current_user

    cached_data = filterable_dashboard_data
    cached_data.entries.each do |key, value|
      instance_variable_set("@#{key}", value)
    end

    render partial: "filterable_dashboard_content"
  end

  def filterable_dashboard
    # Use current_user for /my/home route, otherwise find by id
    @user = if params[:id].present?
      User.find(params[:id])
    else
      current_user
    end

    cached_data = filterable_dashboard_data
    cached_data.entries.each do |key, value|
      instance_variable_set("@#{key}", value)
    end

    if turbo_frame_request?
      render partial: "filterable_dashboard"
    else
      render :show
    end
  end

  private

  def filterable_dashboard_data
    # Cache key based on user and filter parameters
    cache_key = [
      @user,
      params[:projects],
      params[:language],
      params[:os],
      params[:editor]
    ]

    Rails.logger.info "Filterable Dashboard Data - Params: #{params.inspect}"
    Rails.logger.info "Projects param type: #{params[:projects].class}"
    Rails.logger.info "Projects param value: #{params[:projects]}"

    # Load filter options and apply filters with caching
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      result = {}
      # Load filter options
      result[:projects] = @user.heartbeats.select(:project).distinct.order(:project).pluck(:project)
      Rails.logger.info "Available projects: #{result[:projects].inspect}"

      result[:languages] = @user.heartbeats.select(:language).distinct.order(:language).pluck(:language)
      result[:operating_systems] = @user.heartbeats.select(:operating_system).distinct.order(:operating_system).pluck(:operating_system)
      result[:editors] = @user.heartbeats.select(:editor).distinct.order(:editor).pluck(:editor)

      # Apply filters to heartbeats
      filtered_heartbeats = @user.heartbeats

      if params[:projects].present?
        Rails.logger.info "Applying project filter with value: #{params[:projects]}"
        project_filter = params[:projects].split(",")
        Rails.logger.info "Split project filter: #{project_filter.inspect}"
        filtered_heartbeats = filtered_heartbeats.where(project: project_filter)
        Rails.logger.info "SQL query for projects: #{filtered_heartbeats.to_sql}"
      end

      filtered_heartbeats = filtered_heartbeats.where(language: params[:language].split(",")) if params[:language].present?
      filtered_heartbeats = filtered_heartbeats.where(operating_system: params[:os].split(",")) if params[:os].present?
      filtered_heartbeats = filtered_heartbeats.where(editor: params[:editor].split(",")) if params[:editor].present?

      result[:filtered_heartbeats] = filtered_heartbeats

      # Calculate stats for filtered data
      result[:total_time] = filtered_heartbeats.duration_seconds
      result[:total_heartbeats] = filtered_heartbeats.count
      result[:top_project] = filtered_heartbeats.group(:project).duration_seconds.max_by { |_, v| v }&.first
      result[:top_language] = filtered_heartbeats.group(:language).duration_seconds.max_by { |_, v| v }&.first
      result[:top_os] = filtered_heartbeats.group(:operating_system).duration_seconds.max_by { |_, v| v }&.first
      result[:top_editor] = filtered_heartbeats.group(:editor).duration_seconds.max_by { |_, v| v }&.first

      # Prepare project durations data
      result[:project_durations] = filtered_heartbeats
        .group(:project)
        .duration_seconds
        .sort_by { |_, duration| -duration }
        .first(10)
        .to_h

      # Prepare pie chart data
      result[:language_stats] = filtered_heartbeats
        .group(:language)
        .duration_seconds
        .sort_by { |_, duration| -duration }
        .first(10)
        .map { |k, v| [ k.presence || "Unknown", v ] }
        .to_h

      result[:editor_stats] = filtered_heartbeats
        .group(:editor)
        .duration_seconds
        .sort_by { |_, duration| -duration }
        .map { |k, v| [ k.presence || "Unknown", v ] }
        .to_h

      result[:os_stats] = filtered_heartbeats
        .group(:operating_system)
        .duration_seconds
        .sort_by { |_, duration| -duration }
        .map { |k, v| [ k.presence || "Unknown", v ] }
        .to_h

      # Calculate weekly project stats for the last 6 months
      result[:weekly_project_stats] = {}
      (0..25).each do |week_offset|  # 26 weeks = 6 months
        week_start = week_offset.weeks.ago.beginning_of_week
        week_end = week_offset.weeks.ago.end_of_week

        week_stats = filtered_heartbeats
          .where(time: week_start.to_f..week_end.to_f)
          .group(:project)
          .duration_seconds

        result[:weekly_project_stats][week_start.to_date.iso8601] = week_stats
      end

      result
    end
  end

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "You are not authorized to access this page"
    end
  end

  def require_current_user
    unless @user == current_user
      redirect_to root_path, alert: "You are not authorized to access this page"
    end
  end

  def set_user
    @user = if params["id"].present?
      User.find_by!(slack_uid: params["id"])
    else
      current_user
    end

    redirect_to root_path, alert: "You need to log in!" if @user.nil?
  end

  def is_own_settings?
    @is_own_settings ||= !params["id"].present?
  end

  def user_params
    params.require(:user).permit(:uses_slack_status, :hackatime_extension_text_type, :timezone)
  end
end

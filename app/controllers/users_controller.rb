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

    # Load filter options
    @projects = @user.heartbeats.select(:project).distinct.order(:project).pluck(:project)
    @languages = @user.heartbeats.select(:language).distinct.order(:language).pluck(:language)
    @operating_systems = @user.heartbeats.select(:operating_system).distinct.order(:operating_system).pluck(:operating_system)
    @editors = @user.heartbeats.select(:editor).distinct.order(:editor).pluck(:editor)

    # Apply filters to heartbeats
    @filtered_heartbeats = @user.heartbeats
    @filtered_heartbeats = @filtered_heartbeats.where(project: params[:projects].split(",")) if params[:projects].present?
    @filtered_heartbeats = @filtered_heartbeats.where(language: params[:language].split(",")) if params[:language].present?
    @filtered_heartbeats = @filtered_heartbeats.where(operating_system: params[:os].split(",")) if params[:os].present?
    @filtered_heartbeats = @filtered_heartbeats.where(editor: params[:editor].split(",")) if params[:editor].present?

    # Calculate stats for filtered data
    @total_time = @filtered_heartbeats.duration_seconds
    @total_heartbeats = @filtered_heartbeats.count
    @top_project = @filtered_heartbeats.group(:project).duration_seconds.max_by { |_, v| v }&.first
    @top_language = @filtered_heartbeats.group(:language).duration_seconds.max_by { |_, v| v }&.first
    @top_os = @filtered_heartbeats.group(:operating_system).duration_seconds.max_by { |_, v| v }&.first
    @top_editor = @filtered_heartbeats.group(:editor).duration_seconds.max_by { |_, v| v }&.first

    # Prepare project durations data
    @project_durations = @filtered_heartbeats
      .group(:project)
      .duration_seconds
      .sort_by { |_, duration| -duration }
      .first(10)
      .to_h

    # Prepare pie chart data
    @language_stats = @filtered_heartbeats
      .group(:language)
      .duration_seconds
      .sort_by { |_, duration| -duration }
      .first(10)
      .map { |k, v| [ k.presence || "Unknown", v ] }
      .to_h

    @editor_stats = @filtered_heartbeats
      .group(:editor)
      .duration_seconds
      .sort_by { |_, duration| -duration }
      .map { |k, v| [ NameNormalizerService.normalize_editor(k), v ] }
      .to_h

    @os_stats = @filtered_heartbeats
      .group(:operating_system)
      .duration_seconds
      .sort_by { |_, duration| -duration }
      .map { |k, v| [ NameNormalizerService.normalize_os(k), v ] }
      .to_h

    # Calculate weekly project stats for the last 6 months
    @weekly_project_stats = {}
    (0..25).each do |week_offset|  # 26 weeks = 6 months
      week_start = week_offset.weeks.ago.beginning_of_week
      week_end = week_offset.weeks.ago.end_of_week

      week_stats = @filtered_heartbeats
        .where(time: week_start.to_f..week_end.to_f)
        .group(:project)
        .duration_seconds

      @weekly_project_stats[week_start.to_date.iso8601] = week_stats
    end

    respond_to do |format|
      format.html do
        if request.xhr?
          render partial: "filterable_dashboard"
        end
      end

      format.json do
        render json: {
          stats: {
            total_time: ApplicationController.helpers.short_time_simple(@total_time),
            total_heartbeats: number_with_delimiter(@total_heartbeats),
            top_project: @top_project || "None",
            top_language: @top_language || "Unknown",
            top_os: @top_os || "Unknown",
            top_editor: @top_editor || "Unknown"
          },
          project_durations: @project_durations.transform_values { |v|
            {
              seconds: v,
              formatted: ApplicationController.helpers.short_time_simple(v)
            }
          },
          language_stats: @language_stats,
          editor_stats: @editor_stats,
          os_stats: @os_stats,
          weekly_project_stats: @weekly_project_stats
        }
      end
    end
  end

  private

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

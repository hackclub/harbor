class UsersController < ApplicationController
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
    params.require(:user).permit(:uses_slack_status, :hackatime_extension_text_type)
  end
end

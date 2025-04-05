class Api::V1::Neighborhood::ExternalDurationsController < ApplicationController
  include ApiKeyAuthenticatable
  before_action :ensure_authenticated!

  def lookup_by_email
    email_address = EmailAddress.find_by(email: params[:email])
    if email_address.present?
      user = email_address.user
      render json: { user_id: user.id }, status: :ok
    else
      render json: { error: "User not found" }, status: :not_found
    end
  end

  def lookup_by_slack
    user = User.find_by(slack_uid: params[:slack_uid])
    if user.present?
      render json: { user_id: user.id }, status: :ok
    else
      render json: { error: "User not found" }, status: :not_found
    end
  end

  def create
    render json: { error: "Unauthorized" }, status: :unauthorized unless @ysws_provider.present?

    external_duration = @ysws_provider.external_durations.create(external_duration_params)
    if external_duration.persisted?
      render json: external_duration, status: :created
    else
      render json: { error: external_duration.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def external_duration_params
    params.require(:external_duration).permit(:duration, :start_date, :end_date, :user_id)
  end

  def ensure_authenticated!
    api_key = find_api_key
    render json: { error: "Unauthorized" }, status: :unauthorized unless api_key.present?
    return if api_key.blank?

    @ysws_provider = api_key.owner
    unless @ysws_provider.name == "Neighborhood"
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def owner_type
    "YswsProvider"
  end
end

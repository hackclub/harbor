class Api::V1::UserController < ApplicationController
  before_action :authenticate_api_key

  def show
    render json: { user_id: @current_user.id }
  end

  private

  def authenticate_api_key
    api_key = request.headers[ "Authorization" ]&.split( " " )&.last
    return render json: { error: "Unauthorized" }, status: :unauthorized unless api_key

    api_key_record = ApiKey.find_by(token: api_key)
    return render json: { error: "Unauthorized" }, status: :unauthorized unless api_key_record

    @current_user = api_key_record.user
  end
end

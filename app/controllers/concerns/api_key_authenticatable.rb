module ApiKeyAuthenticatable
  extend ActiveSupport::Concern

  private

  def ensure_authenticated!
    api_key = find_api_key
    render plain: "Unauthorized", status: :unauthorized unless api_key.present?

    if owner_type.present? && api_key.owner_type != owner_type
      render plain: "Unauthorized", status: :unauthorized
    end

    @current_api_key = api_key
    @current_user = api_key.user
  end

  def find_api_key
    api_header = request.headers["Authorization"]
    token = api_header&.split(" ")&.last
    token ||= params[:api_key]

    ApiKey.find_by(token: token)
  end

  def current_user
    @current_user
  end

  def current_api_key
    @current_api_key
  end

  # Override this method in controllers that need to restrict API key ownership
  def owner_type
    nil
  end
end

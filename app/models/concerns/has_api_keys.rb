module HasApiKeys
  extend ActiveSupport::Concern

  included do
    has_many :api_keys, as: :owner, dependent: :destroy
  end

  def generate_api_key(name: "API Key")
    api_keys.create!(name: name)
  end

  def api_key
    api_keys.last&.token
  end
end

class OneTime::CreateYswsProviderJob < ApplicationJob
  queue_as :default

  def perform(name)
    ysws_provider = YswsProvider.find_or_create_by!(name: name)
    # create api key for the provider
    api_key = ApiKey.find_or_create_by!(owner: ysws_provider, name: "API Key")

    puts "Created YswsProvider #{name} with API Key #{api_key.token}"
  end
end

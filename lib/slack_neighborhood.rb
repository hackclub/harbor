# https://l.hack.club/personal

class SlackNeighborhood
  def self.find_by_id(id)
    # Get the neighborhood data from the cache or fetch it from the API
    key = "slack_neighborhood_#{id}"

    specific_neighborhood = Rails.cache.fetch(key, expires_in: 10.days) do
      neighborhood_data = Rails.cache.fetch("slack_neighborhood_list", expires_in: 10.hours) do
        response = HTTP.get("https://l.hack.club/personal")
        JSON.parse(response.body)
      end

      neighborhood_data.find { |neighborhood| neighborhood["channelManagers"].include?(id) }
    end

    Rails.cache.delete(key) if specific_neighborhood.nil?

    specific_neighborhood
  rescue StandardError => e
    Rails.logger.error("Error in SlackNeighborhood.find_by_id: #{e.message}")
    nil
  end
end

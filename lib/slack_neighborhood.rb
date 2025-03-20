# https://l.hack.club/personal

class SlackNeighborhood
  def self.find_by_id(id)
    neighborhood_data = Rails.cache.fetch("slack_neighborhood_list", expires_in: 1.hour) do
      response = HTTP.get("https://l.hack.club/personal")
      JSON.parse(response.body)
    end

    specific_neighborhood = Rails.cache.fetch("slack_neighborhood_#{id}", expires_in: 1.hour) do
      neighborhood_data.find { |neighborhood| neighborhood["channelManagers"].include?(id) }
    end

    specific_neighborhood
  end
end

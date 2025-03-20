class SlackUsernameUpdateJob < ApplicationJob
  queue_as :default

  include GoodJob::ActiveJobExtensions::Concurrency

  # Limits concurrency to 1 job per date
  good_job_control_concurrency_with(
    total: 1,
    drop: true
  )

  def perform
    # in batches of 100, update the slack info for each user
    User.where.not(slack_uid: nil).find_each(batch_size: 100) do |user|
      begin
        user_response = HTTP.auth("Bearer #{user.slack_access_token}")
          .get("https://slack.com/api/users.info?user=#{user.slack_uid}")

        user_data = JSON.parse(user_response.body.to_s)

        next unless user_data["ok"]

        user.username = user_data.dig("user", "profile", "username")
        user.username ||= user_data.dig("user", "profile", "display_name_normalized")
        user.slack_username = user_data.dig("user", "profile", "username")
        user.slack_username ||= user_data.dig("user", "profile", "display_name_normalized")
        user.slack_avatar_url = user_data.dig("user", "profile", "image_192") || user_data.dig("user", "profile", "image_72")
        user.save!
      rescue => e
        Rails.logger.error "Failed to update Slack username and avatar for user #{user.id}: #{e.message}"
      end
    end
  end
end

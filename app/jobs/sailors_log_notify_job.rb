class SailorsLogNotifyJob < ApplicationJob
  queue_as :default

  def perform(sailors_log_slack_notification_id)
    slsn = SailorsLogSlackNotification.find(sailors_log_slack_notification_id)

    slack_uid = slsn.slack_uid
    slack_channel_id = slsn.slack_channel_id
    project_name = slsn.project_name
    project_duration = slsn.project_duration

    kudos_message = [
      "Great work!",
      "Nice job!",
      "Amazing!",
      "Fantastic!",
      "Excellent!",
      "Awesome!",
      "Well done!",
      "Wahoo!",
      "Way to go!"
    ].sample

    hours = project_duration / 3600

    message = ":boat: `@#{SlackUsername.find_by_uid(slack_uid)}` just coded 1 more hour on *#{project_name}* (total: #{hours}hrs). _#{kudos_message}_"

    response = HTTP.auth("Bearer #{ENV['SAILORS_LOG_SLACK_BOT_OAUTH_TOKEN']}")
      .post("https://slack.com/api/chat.postMessage",
            json: {
              channel: slack_channel_id,
              text: message
            })

    response_data = JSON.parse(response.body)
    if response_data["ok"]
      slsn.update(sent: true)
      SailorsLogTeletypeJob.perform_later(message)
    else
      Rails.logger.error("Failed to send Slack notification: #{response_data["error"]}")
      if response_data["error"] == "channel_not_found"
        # disable any preferences for this channel
        SailorsLogNotificationPreference.where(slack_channel_id: slack_channel_id).update_all(enabled: false)
      else
        throw "Failed to send Slack notification: #{response_data["error"]} in #{slack_channel_id}"
      end
    end
  end
end

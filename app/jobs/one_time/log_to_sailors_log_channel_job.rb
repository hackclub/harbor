class OneTime::LogToSailorsLogChannelJob < ApplicationJob
  queue_as :default

  def perform
    # every user should have a sailors_log &
    # every sailors_log should atleast have a notification_preference for the debug sailors_log channel
    User.where.missing(:sailors_log)
        .where.not(slack_uid: nil)
        .pluck(:slack_uid).each do |slack_uid|
          puts "creating sailors_log for #{slack_uid}"
          SailorsLog.create!(slack_uid: slack_uid)
        end

    # Find SailorsLogs that don't have a notification preference for the debug channel
    debug_channel_id = "C0835AZP9GB"

    # Get all SailorsLogs
    SailorsLog.find_each do |sailors_log|
      # Check if this SailorsLog already has a notification preference for the debug channel
      has_preference = sailors_log.notification_preferences.exists?(slack_channel_id: debug_channel_id)

      # If not, create one
      unless has_preference
        puts "Creating notification preference for #{sailors_log.slack_uid}"
        sailors_log.notification_preferences.create!(
          slack_channel_id: debug_channel_id,
          enabled: true
        )
      end
    end
  end
end

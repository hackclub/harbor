class SailorsLogPollForChangesJob < ApplicationJob
  queue_as :default

  def perform
    puts "performing SailorsLogPollForChangesJob"
    # get all users who've coded in the last minute
    users_who_coded = Heartbeat.where("created_at > ?", 1.minutes.ago)
                               .where(time: 1.minutes.ago..)
                               .distinct.pluck(:user_id)

    puts "users_who_coded: #{users_who_coded}"
    slack_uids = User.where(id: users_who_coded)
                     .where.not(slack_uid: nil)
                     .distinct.pluck(:slack_uid)

    # Get all of those with enabled preferences
    enabled_users = SailorsLogNotificationPreference.where(enabled: true, slack_uid: slack_uids).distinct.pluck(:slack_uid)

    puts "enabled_users: #{enabled_users}"

    logs = SailorsLog.where(slack_uid: enabled_users)

    puts "logs: #{logs}"

    logs.each do |log|
      # get all projects for the user with duration
      new_project_times = Heartbeat.where(user_id: log.slack_uid)
                                              .group(:project)
                                              .duration_seconds

      new_project_times.each do |project, new_project_duration|
        next if project.blank?
        if new_project_duration > (log.projects_summary[project] || 0) + 1.hour
          log.notification_preferences.each do |preference|
            log.notifications << SailorsLogSlackNotification.new(
              slack_uid: log.slack_uid,
              slack_channel_id: preference.slack_channel_id,
              project_name: project,
              project_duration: new_project_duration
            )
          end
          log.projects_summary[project] = new_project_duration
        end
      end
      log.save! if log.changed?

      # if multiple notifications for the same project, only the most recent one should be sent
      log.notifications.group_by(&:project_name).each do |project_name, notifications|
        if notifications.size > 1
          # Keep the most recent notification, destroy the older ones
          notifications.sort_by(&:created_at)[0..-2].each(&:destroy)
        end
      end
    end
  end
end

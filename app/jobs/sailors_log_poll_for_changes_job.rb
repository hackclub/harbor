class SailorsLogPollForChangesJob < ApplicationJob
  queue_as :default

  def perform
    puts "performing SailorsLogPollForChangesJob"
    users_who_coded = Heartbeat.with_valid_timestamps
                               .where(time: 10.minutes.ago..)
                               .distinct.pluck(:user_id)
    puts "users_who_coded: #{users_who_coded}"

    slack_uids = User.where(id: users_who_coded).pluck(:slack_uid)
    puts "slack_uids: #{slack_uids}"

    new_notifs = SailorsLog.includes(:user, :notification_preferences)
                           .where(notification_preferences: { enabled: true })
                           .where(slack_uid: slack_uids)
                           .map { |sl| update_sailors_log(sl) }.flatten

    notifs_to_send = SailorsLogSlackNotification.insert_all(new_notifs)
    notif_ids = notifs_to_send.result.to_a.map { |r| r["id"] }

    SailorsLogSlackNotification.where(id: notif_ids).map(&:notify_user_later!)
  end

  private

  def update_sailors_log(sailors_log)
    project_updates = []
    project_durations = Heartbeat.where(user_id: sailors_log.user.id)
                                 .group(:project).duration_seconds
    project_durations.each do |k, v|
      old_duration = sailors_log.projects_summary[k] || 0
      new_duration = v
      puts "#{k}| old_duration: #{old_duration}, new_duration: #{new_duration}"
      if old_duration / 3600 < new_duration / 3600
        puts "updating #{k} to #{new_duration}"
        sailors_log.projects_summary[k] = new_duration
        project_updates << { project: k, duration: new_duration }
      end
    end

    notifications_to_create = []
    if sailors_log.changed?
      sailors_log.notification_preferences.each do |np|
        project_updates.map do |pu|
          puts "np: #{np.inspect}, pu: #{pu.inspect}"
          notifications_to_create << {
            slack_uid: sailors_log.user.slack_uid,
            slack_channel_id: np.slack_channel_id,
            project_name: pu[:project],
            project_duration: pu[:duration]
          }
        end
      end

      sailors_log.save!
    end

    notifications_to_create
  end
end

# optimizations?
# - index heartbeats on user_id + project so we can call duration_seconds grouping by both
# - investigate lookup by slack_uid, maybe index or computed field?

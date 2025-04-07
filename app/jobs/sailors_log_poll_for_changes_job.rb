class SailorsLogPollForChangesJob < ApplicationJob
  queue_as :default

  def perform
    puts "performing SailorsLogPollForChangesJob"
    users_who_coded = Heartbeat.where("created_at > ?", 1.minutes.ago)
                               .where(time: 1.minutes.ago..)
                               .distinct.pluck(:user_id)
    puts "users_who_coded: #{users_who_coded}"

    new_notifs = SailorsLog.includes(:user, :notification_preference)
                           .where(notification_preference: { enabled: true })
                           .where(user_id: users_who_coded)
                           .each(&:update_sailors_log)
    
    # create notifications
    # background job to notify user
    notifs_to_send = Heartbeat.insert_all(new_notifs)

    notifs_to_send.map(&:notify_user_later!)
  end

  private

  def update_sailors_log(sailors_log)
    project_durations = sailors_log.user.duration_seconds.group(:project)
    project_updates = []
    project_durations.each do |k, v|
      # TODO: check if project duration is in hours or seconds
      old_duration = sailors_log.projects_summary[k]
      new_duration = v / 3600
      if (old_duration < new_duration)
        sailors_log.projects_summary[k] = new_duration
        project_updates << { project: k, duration: new_duration }
      end
    end

    notifications_to_create = []
    if sailors_log.changed?
      sailors_log.save!
      # for each notification_preference, for each project_update
      sailors_log.notification_preference.each do |np|
        project_updates.map do |pu|
          notifications_to_create << {
            slack_uid: sailors_log.user.slack_uid,
            slack_channel_id: np.slack_channel_id,
            project_name: pu.project,
            project_duration: pu.duration
          }
        end
      end

    end

    notifications_to_create
  end
end

# optimizations?
# - index heartbeats on user_id + project so we can call duration_seconds grouping by both
# - investigate lookup by slack_uid, maybe index or computed field?
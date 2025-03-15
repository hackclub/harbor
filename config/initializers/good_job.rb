Rails.application.configure do
  config.good_job.preserve_job_records = true
  config.good_job.enable_cron = true
  config.good_job.execution_mode = :async

  config.good_job.cron = {
    update_slack_status: {
      cron: "*/5 * * * *",
      class: "UserSlackStatusUpdateJob"
    },
    daily_leaderboard_update: {
      cron: "*/5 * * * *",
      class: "LeaderboardUpdateJob",
      args: [ :daily ]
    },
    weekly_leaderboard_update: {
      cron: "0 0 * * *",
      class: "LeaderboardUpdateJob",
      args: [ :weekly ]
    },
    sailors_log_poll: {
      cron: "* * * * *",
      class: "SailorsLogPollForChangesJob"
    },
    update_slack_channel_cache: {
      cron: "0 11 * * *",
      class: "SlackCommand::UpdateSlackChannelCacheJob"
    },
    slack_username_update: {
      cron: "0 0 * * *",
      class: "SlackUsernameUpdateJob"
    }
  }
end

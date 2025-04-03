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
      cron: "* * * * *",
      class: "LeaderboardUpdateJob",
      args: [ :daily ]
    },
    weekly_leaderboard_update: {
      cron: "*/2 * * * *",
      class: "LeaderboardUpdateJob",
      args: [ :weekly ]
    },
    last_7_days_leaderboard_update: {
      cron: "*/7 * * * *",
      class: "LeaderboardUpdateJob",
      args: [ :last_7_days ]
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
    },
    cache_home_stats: {
      cron: "0/10 * * * *",
      class: "CacheHomeStatsJob"
    },
    scan_github_repos: {
      cron: "0 10 * * *",
      class: "ScanGithubReposJob"
    }
  }
end

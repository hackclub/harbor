Rails.application.configure do
  config.good_job.preserve_job_records = true
  config.good_job.enable_cron = true
  config.good_job.execution_mode = :async

  # https://github.com/bensheldon/good_job#configuring-your-queues
  config.good_job.queues = "latency_10s:2; latency_1m:2; *:2"

  #  https://github.com/bensheldon/good_job#pgbouncer-compatibility
  GoodJob.active_record_parent_class = "ApplicationDirectRecord"

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
    scan_github_repos: {
      cron: "0 10 * * *",
      class: "ScanGithubReposJob"
    },
    cleanup_expired_email_verification_requests: {
      cron: "* * * * *",
      class: "CleanupExpiredEmailVerificationRequestsJob"
    },
    cache_active_user_graph_data_job: {
      cron: "*/10 * * * *",
      class: "Cache::ActiveUsersGraphDataJob",
      kwargs: { force_reload: true }
    },
    cache_currently_hacking: {
      cron: "* * * * *",
      class: "Cache::CurrentlyHackingJob",
      kwargs: { force_reload: true }
    },
    cache_home_stats: {
      cron: "*/10 * * * *",
      class: "Cache::HomeStatsJob",
      kwargs: { force_reload: true }
    },
    cache_active_projects: {
      cron: "* * * * *",
      class: "Cache::ActiveProjectsJob",
      kwargs: { force_reload: true }
    },
    cache_social_proof: {
      cron: "* * * * *",
      class: "Cache::SocialProofJob",
      kwargs: { force_reload: true }
    },
    cache_minutes_logged: {
      cron: "* * * * *",
      class: "Cache::MinutesLoggedJob",
      kwargs: { force_reload: true }
    }
  }
end

class Cache::ActiveProjectsJob
  include GoodJob::ActiveJobExtensions::Concurrency

  # Limits concurrency to 1 job per date
  good_job_control_concurrency_with(
    total: 1,
    drop: true
  )

  def perform(force_reload: false)
    key = "active_projects"
    expiration = 15.minutes
    Rails.cache.write(key, calculate, expires_in: expiration) if force_reload

    Rails.cache.fetch(key, expires_in: expiration,) do
      calculate
    end
  end

  private

  def calculate
    # TODO: check if we can join heartbeats to project_repo_mappings through users
    recent_heartbeats = Heartbeat.where(source_type: :direct_entry)
                                 .where(time: 5.minutes.ago.to_f..CurrenTime.current)
                                 .includes(user: :project_repo_mappings)
                                 .select("DISTINCT ON (user_id) user_id, project, time")
                                 .order("user_id, time DESC")
                                 .index_by(&:user_id)

    # return a hash of user to project_repo_mappings
  end
end

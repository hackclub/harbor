class WakatimeClearTestHeartbeatsJob < ApplicationJob
  queue_as :default

  include GoodJob::ActiveJobExtensions::Concurrency

  # Limits concurrency to 1 job per date
  good_job_control_concurrency_with(
    total: 1,
    drop: true
  )

  def perform
    Heartbeat.where(source_type: "test_entry")
             .where("created_at < ?", 7.days.ago)
             .delete_all
  end
end

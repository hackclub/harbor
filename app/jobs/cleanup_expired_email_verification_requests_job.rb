class CleanupExpiredEmailVerificationRequestsJob < ApplicationJob
  queue_as :interval_10s

  def perform
    # Soft delete all expired and non-deleted verification requests in a single query
    EmailVerificationRequest.expired.where(deleted_at: nil)
                            .update_all(deleted_at: Time.current)
  end
end

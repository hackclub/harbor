class MembershipEligibilityNotificationJob < ApplicationJob
  def perform
    users_with_new_ysws_records.each do |user|
      if user.eligible_for_next_status?
        puts "User: #{user.email_addresses.first.email}"
        puts "Current status: #{user.current_status}"
        puts "Eligible for next status: #{user.eligible_for_next_status?}"
        next if user.next_status.nil?

        specific_project = user.ysws_projects.where(approved_at: 4.days.ago..).last
        specific_project_link = specific_project.try(:code_url)

        MembershipMailer.notify_eligible_for_status(user,
                                                    user.next_status,
                                                    specific_project,
                                                    specific_project_link).deliver_now

        user.update!(membership_eligibility_sent_for_status: user.next_status)
      end
    end
  end

  private

  def users_with_new_ysws_records
    @users_with_new_ysws_records ||= begin
      ea = ::Warehouse::UnifiedYsws::ApprovedProject.where(approved_at: 4.days.ago..)
                                                    .distinct.pluck(:email)

      user_ids = EmailAddress.where(email: ea).pluck(:user_id)
      User.where(id: user_ids)
          .where.not(membership_eligibility_sent_for_status: User.membership_types.last)
          .where.not(membership_upgrade_requests: { status: :pending })
    end
  end
end

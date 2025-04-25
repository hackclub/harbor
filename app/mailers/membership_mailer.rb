class MembershipMailer < ApplicationMailer
  def notify_eligible_for_status(user, status, specific_project, specific_project_link)
    @user = user
    @status = status
    @specific_project = specific_project
    @specific_project_link = specific_project_link

    mail(
      to: user.email_addresses.first.email,
      subject: "Welcome to Hack Club's #{status} membership!"
    )
  end
end

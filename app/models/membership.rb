class Membership
  attr_reader :user

  # This is a virtual model that is used to store the membership information for
  # a user– it's not a real model in the database

  def initialize(user)
    @user = user
  end

  def total_hours
    @total_hours ||= ysws_projects.sum do |project|
      # handle if the Hours Spent is an array
      if project["hours_spent"].is_a?(Array)
        project["hours_spent"].first
      else
        project["hours_spent"] || 0.0
      end
    end.round(1)
  end

  def ysws_projects
    @ysws_projects ||= begin
      user_emails = @user.email_addresses.pluck(:email)
      ::Warehouse::UnifiedYsws::ApprovedProject.where(email: user_emails)
    end
  end

  def member_since
    @member_since ||= begin
      user_emails = @user.email_addresses.pluck(:email)
      ::Warehouse::ProgramEngagement::HackClubber.where(email: user_emails).minimum(:first_engagement_at)
    end
  end

  def current_status
    case total_hours
    when 0...10
      :basic
    when 10...80
      :bronze
    when 80...200
      :silver
    when 200...500
      :gold
    else
      :diamond
    end
  end

  def humanized_status
    {
      basic: "Basic",
      bronze: "Preferred Bronze",
      silver: "Preferred Silver",
      gold: "Preferred Gold",
      diamond: "Preferred Diamond"
    }[current_status]
  end
end

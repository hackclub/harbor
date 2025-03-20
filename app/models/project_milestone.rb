class ProjectMilestone < ApplicationRecord
  belongs_to :user, foreign_key: :user_id

  has_many :project_milestone_kudos, class_name: "ProjectMilestoneKudos"

  validates :project_name, presence: true
  validates :milestone_type, presence: true
  validates :milestone_value, presence: true

  enum :milestone_type, {
    hourly: 0,
    daily: 1,
    weekly: 2
  }

  # Get milestones for display in the sidebar
  def self.recent_for_display(limit = 20)
    order(created_at: :desc)
      .includes(:user, :project_milestone_kudos)
      .limit(limit)
  end

  # Check if the current user has given kudos to this milestone
  def kudos_from?(user_id)
    project_milestone_kudos.where(user_id: user_id).exists?
  end

  # Get the kudos count
  def kudos_count
    project_milestone_kudos.count
  end

  # Format the milestone message
  def formatted_message
    case milestone_type
    when "hourly"
      "completed #{milestone_value} hour#{'s' if milestone_value > 1} on #{project_name}"
    when "daily"
      "worked on #{project_name} for #{ApplicationController.helpers.short_time_simple(milestone_value)} today"
    when "weekly"
      "spent #{ApplicationController.helpers.short_time_simple(milestone_value)} on #{project_name} this week"
    end
  end
end

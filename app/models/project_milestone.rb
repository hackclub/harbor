class ProjectMilestone < ApplicationRecord
  belongs_to :user, foreign_key: :user_id

  has_many :project_milestone_kudos, class_name: "ProjectMilestoneKudos"

  validates :project_name, presence: true
  validates :milestone_type, presence: true
  validates :milestone_value, presence: true

  # We keep this because I don't want to change the database schema
  enum :milestone_type, {
    hourly: 0,
    daily: 1,
    weekly: 2
  }

  # Get milestones for display in the sidebar
  def self.recent_for_display(limit = 20)
    where(milestone_type: :hourly)
      .order(created_at: :desc)
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

  def formatted_message
    "completed #{milestone_value} hour#{'s' if milestone_value > 1} on #{project_name}"
  end
end
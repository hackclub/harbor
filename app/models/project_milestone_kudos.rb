class ProjectMilestoneKudos < ApplicationRecord
  belongs_to :project_milestone
  belongs_to :user

  validates :project_milestone_id, uniqueness: { scope: :user_id }
end

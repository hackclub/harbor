class ProjectMilestoneCheckJob < ApplicationJob
  queue_as :default

  def perform
    # Get all users with heartbeats in the last hour
    active_users = Heartbeat.where("created_at > ?", 1.hour.ago)
                          .distinct.pluck(:user_id)

    active_users.each do |user_id|
      check_hourly_milestones(user_id)
    end
  end

  private

  def check_hourly_milestones(user_id)
    user = User.find_by(id: user_id)
    return unless user

    # Get projects with significant time in the last period
    project_durations = user.heartbeats.today.group(:project).duration_seconds

    project_durations.each do |project, duration|
      next if project.blank?

      # Convert to hours
      hours = (duration / 3600.0).floor
      next if hours < 1

      # Check if we already have a milestone for this hour count
      existing = ProjectMilestone.where(
        user_id: user_id,
        project_name: project,
        milestone_type: :hourly,
        milestone_value: hours
      ).where("created_at > ?", 1.day.ago).exists?

      # If no milestone exists, create one
      unless existing
        ProjectMilestone.create!(
          user_id: user_id,
          project_name: project,
          milestone_type: :hourly,
          milestone_value: hours
        )
        Rails.logger.info "Created hourly milestone for user #{user_id} on project #{project}: #{hours} hours"
      end
    end
  end
end

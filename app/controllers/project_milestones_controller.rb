class ProjectMilestonesController < ApplicationController
  before_action :authenticate_user!

  def give_kudos
    milestone = ProjectMilestone.find(params[:id])

    # Don't allow users to give kudos to themselves
    if milestone.user_id == current_user.id
      return render json: { error: "You cannot give kudos to yourself" }, status: :unprocessable_entity
    end

    # Check if user already gave kudos
    if milestone.kudos_from?(current_user.id)
      return render json: { error: "You already gave kudos for this milestone" }, status: :unprocessable_entity
    end

    kudos = ProjectMilestoneKudos.new(
      project_milestone: milestone,
      user_id: current_user.id
    )

    if kudos.save
      render json: {
        success: true,
        kudos_count: milestone.reload.kudos_count
      }
    else
      render json: { error: kudos.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end
end

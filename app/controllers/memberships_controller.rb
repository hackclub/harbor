class MembershipsController < ApplicationController
  before_action :set_membership, only: [ :show ]

  def index
  end

  def show
    @eligible_for_upgrade = @user.eligible_for_next_status?
  end

  private

  def set_membership
    set_user
    @membership = Membership.new(@user)
  end

  def set_user
    @user = begin
      if params[:slack_uid] == "my"
        current_user
      else
        User.find_by!(slack_uid: params[:slack_uid])
      end
    rescue
      nil
    end
  end
end

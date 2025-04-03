class LeaderboardsController < ApplicationController
  def index
    @period_type = (params[:period_type] || "daily").to_sym
    @period_type = :daily unless [ :daily, :weekly, :last_7_days ].include?(@period_type)

    start_date = case @period_type
    when :weekly
      Date.current.beginning_of_week
    when :last_7_days
      Date.current
    else
      Date.current
    end

    @leaderboard = Leaderboard.find_by(
      start_date: start_date,
      period_type: @period_type,
      deleted_at: nil
    )

    if @leaderboard.nil?
      LeaderboardUpdateJob.perform_later(start_date, @period_type)
      flash.now[:notice] = "Leaderboard is being updated..."
    else
      @entries = @leaderboard.entries
                             .includes(:user)
                             .order(total_seconds: :desc)

      tracked_user_ids = @leaderboard.entries.distinct.pluck(:user_id)

      @user_on_leaderboard = current_user && tracked_user_ids.include?(current_user.id)
      unless @user_on_leaderboard
        time_range = case @period_type
        when :weekly
          (start_date.beginning_of_day...(start_date + 7.days).beginning_of_day)
        when :last_7_days
          ((start_date - 6.days).beginning_of_day...start_date.end_of_day)
        else
          start_date.all_day
        end

        @untracked_entries = Hackatime::Heartbeat
            .where(time: time_range)
            .distinct
            .pluck(:user_id)
            .count { |user_id| !tracked_user_ids.include?(user_id) }
      end

      # Get active projects for the leaderboard entries
      if @entries&.any?
        user_ids = @entries.pluck(:user_id)
        users = User.where(id: user_ids).includes(:project_repo_mappings)
        @active_projects = {}
        users.each do |user|
          @active_projects[user.id] = user.project_repo_mappings.find { |p| p.project_name == user.active_project }
        end
      end
    end
  end
end

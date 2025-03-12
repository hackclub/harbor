class LeaderboardsController < ApplicationController
  def index
    @leaderboard = Leaderboard.find_by(start_date: Date.current, deleted_at: nil)
    @entries = []

    if @leaderboard.nil?
      LeaderboardUpdateJob.perform_later
      flash.now[:notice] = "Leaderboard is being updated..."
    else
      @entries = @leaderboard.entries
                             .includes(:user)
                             .order(total_seconds: :desc)

      tracked_user_ids = @leaderboard.entries.distinct.pluck(:slack_uid)

      @user_on_leaderboard = current_user && tracked_user_ids.include?(current_user.slack_uid)
      unless @user_on_leaderboard
        today = Time.current
        @untracked_entries = Hackatime::Heartbeat
            .where(time: today.beginning_of_day..today.end_of_day)
            .distinct
            .pluck(:user_id)
            .count { |user_id| !tracked_user_ids.include?(user_id) }
      end
    end
  end
end

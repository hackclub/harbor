class LeaderboardsController < ApplicationController
  def index
    @leaderboard = Leaderboard.find_by(start_date: Date.current, deleted_at: nil)

    if @leaderboard.nil?
      LeaderboardUpdateJob.perform_later
      flash.now[:notice] = "Leaderboard is being updated..."
    else
      @entries = @leaderboard.entries
        .includes(:user)
        .order(total_seconds: :desc)

      all_slack_uids = User.pluck(:slack_uid) - @entries.pluck(:slack_uid)
      @untracked_entries = Hackatime::Heartbeat.today
                                               .where(user_id: all_slack_uids)
                                               .distinct.pluck(:user_id)
                                               .size
    end
  end
end

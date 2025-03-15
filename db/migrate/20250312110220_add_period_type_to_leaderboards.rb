class AddPeriodTypeToLeaderboards < ActiveRecord::Migration[8.0]
  def change
    add_column :leaderboards, :period_type, :integer, default: 0, null: false
  end
end

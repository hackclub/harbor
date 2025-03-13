class AllowNullSlackUid < ActiveRecord::Migration[8.0]
  def change
    change_column_null :users, :slack_uid, true
  end
end

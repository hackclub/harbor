class AddSlackUsernameToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :slack_username, :string
  end
end

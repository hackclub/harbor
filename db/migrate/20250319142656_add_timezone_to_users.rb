class AddTimezoneToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :timezone, :string, default: "UTC"
    add_index :users, :timezone
  end
end

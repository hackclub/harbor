class AddMembershipTypeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :membership_type, :integer, default: 0
  end
end

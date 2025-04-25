class AddMembershipEligibilitySentForStatusToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :membership_eligibility_sent_for_status, :integer, default: 0
  end
end

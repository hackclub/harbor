class CreateMembershipUpgradeRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :membership_upgrade_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :from_status
      t.integer :to_status
      t.integer :payment_method
      t.integer :status

      t.timestamps
    end
  end
end

class ExternalDurationsBelongToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :external_durations, :user, null: false, foreign_key: true
  end
end

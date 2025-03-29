class CreateExternalDurations < ActiveRecord::Migration[8.0]
  def change
    create_table :external_durations do |t|
      t.timestamp :start_time
      t.timestamp :end_time

      t.string :provider
      t.string :external_id

      t.integer :type # enum
      t.integer :category # enum
      t.string :project
      t.string :branch
      t.string :language
      t.string :meta

      t.inet :ip_address

      t.timestamps
    end
  end
end

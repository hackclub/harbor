class CreateWakatimeMirrors < ActiveRecord::Migration[8.0]
  def change
    create_table :wakatime_mirrors do |t|
      t.belongs_to :user, null: false, foreign_key: true

      t.string :api_url, null: false
      t.string :api_key, null: false

      t.datetime :deleted_at
      t.datetime :last_synced_at

      t.timestamps
    end
  end
end

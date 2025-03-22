class CreateProjectMilestoneKudos < ActiveRecord::Migration[8.0]
  def change
    create_table :project_milestone_kudos do |t|
      t.references :project_milestone, null: false, foreign_key: true
      t.bigint :user_id, null: false

      t.timestamps
    end

    add_index :project_milestone_kudos, [ :project_milestone_id, :user_id ], unique: true
  end
end

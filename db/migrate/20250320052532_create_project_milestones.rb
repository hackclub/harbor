class CreateProjectMilestones < ActiveRecord::Migration[8.0]
  def change
    create_table :project_milestones do |t|
      t.bigint :user_id, null: false
      t.string :project_name, null: false
      t.integer :milestone_type, null: false, default: 0
      t.integer :milestone_value, null: false
      t.boolean :notified, default: false

      t.timestamps
    end

    add_index :project_milestones, :user_id
    add_index :project_milestones, [ :user_id, :project_name, :milestone_type ]
    add_index :project_milestones, :created_at
  end
end

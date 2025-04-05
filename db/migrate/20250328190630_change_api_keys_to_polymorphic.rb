class ChangeApiKeysToPolymorphic < ActiveRecord::Migration[8.0]
  def change
    # First add the new polymorphic columns
    add_column :api_keys, :owner_type, :string
    add_column :api_keys, :owner_id, :bigint

    # Migrate existing data
    execute <<-SQL
      UPDATE api_keys#{' '}
      SET owner_type = 'User', owner_id = user_id
      WHERE user_id IS NOT NULL
    SQL

    # Make the new columns required after data migration
    change_column_null :api_keys, :owner_type, false
    change_column_null :api_keys, :owner_id, false

    # Add new indexes
    add_index :api_keys, [ :owner_type, :owner_id ]
    add_index :api_keys, [ :owner_type, :owner_id, :name ], unique: true
    add_index :api_keys, [ :owner_type, :owner_id, :token ], unique: true

    # Remove old indexes and column
    remove_index :api_keys, name: "index_api_keys_on_user_id"
    remove_index :api_keys, name: "index_api_keys_on_user_id_and_name"
    remove_index :api_keys, name: "index_api_keys_on_user_id_and_token"
    remove_column :api_keys, :user_id, :bigint
  end
end

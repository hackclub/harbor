class CreateYswsProviders < ActiveRecord::Migration[8.0]
  def change
    create_table :ysws_providers do |t|
      t.timestamps

      t.string :name
    end
  end
end

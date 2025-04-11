class ExternalDurationsBelongToYswsProviders < ActiveRecord::Migration[8.0]
  def change
    add_reference :external_durations, :ysws_provider, null: false, foreign_key: true
  end
end

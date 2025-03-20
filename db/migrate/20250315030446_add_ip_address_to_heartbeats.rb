class AddIpAddressToHeartbeats < ActiveRecord::Migration[8.0]
  def change
    add_column :heartbeats, :ip_address, :inet
  end
end

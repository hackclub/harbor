class WarehouseRecord < ApplicationRecord
  self.abstract_class = true
  connects_to database: { reading: :warehouse, writing: :warehouse }
end

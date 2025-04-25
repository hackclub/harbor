class Warehouse::ProgramEngagement::Program < WarehouseRecord
  self.table_name = "airtable_analytics___program_engagements_appcgb6lccmzwkjzg.programs"

  has_many :hack_clubbers, class_name: "Warehouse::ProgramEngagement::HackClubber", foreign_key: "program_id"
end

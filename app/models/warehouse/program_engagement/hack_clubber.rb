class Warehouse::ProgramEngagement::HackClubber < WarehouseRecord
  self.table_name = "airtable_analytics___program_engagements_appcgb6lccmzwkjzg.hack_clubbers"

  def member_since
    self.first_engagement_at
  end
end

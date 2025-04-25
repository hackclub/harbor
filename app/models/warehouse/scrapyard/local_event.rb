class Warehouse::Scrapyard::LocalEvent < WarehouseRecord
  self.table_name = "airtable_hack_club_scrapyard_appigkif7gbvisalg.events"

  # Prevent these columns from messing with acriverecord
  self.ignored_columns += [ "errors" ]

  # local attendees is a list of airtable ids
  has_many :local_attendees, class_name: "Warehouse::Scrapyard::LocalAttendee", foreign_key: "event_id"
end

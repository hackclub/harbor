class Warehouse::Scrapyard::LocalAttendee < WarehouseRecord
  self.table_name = "airtable_hack_club_scrapyard_appigkif7gbvisalg.local_attendees"

  # The event field in Airtable is a JSONB array with a single event ID
  def event_id
    self[:event]&.first
  end

  # Override the event association to handle the array field
  def event
    return nil if event_id.nil?
    Warehouse::Scrapyard::LocalEvent.find_by(id: event_id)
  end

  # Find the associated user through their email
  def user
    return nil if self[:email].blank?
    EmailAddress.find_by(email: self[:email])&.user
  end

  # Scope to find attendees for a specific event
  scope :for_event, ->(event) {
    where("event ? :event_id", event_id: event.id)
  }
end

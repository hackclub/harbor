class Warehouse::UnifiedYsws::ApprovedProject < WarehouseRecord
  self.table_name = "airtable_unified_ysws_projects_db_app3a5kjwyqxmlogh.approved_projects"

  def find_by_user(user)
    emails = EmailAddress.where(user: user).pluck(:email)
    where(email: emails)
  end

  def humanized_ysws_name
    ysws_name.first
  end
end

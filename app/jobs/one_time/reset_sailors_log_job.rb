class OneTime::ResetSailorsLogJob < ApplicationJob
  queue_as :default

  def perform
    SailorsLog.find_each do |sl|
      next if sl.user.blank?
      sl.projects_summary = nil
      sl.send(:initialize_projects_summary)
      sl.save!
    end
  end
end

class ApplicationDirectRecord < ActiveRecord::Base
  self.abstract_class = true
  connects_to database: { writing: :primary_direct }
end

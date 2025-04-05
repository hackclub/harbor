class YswsProvider < ApplicationRecord
  include HasApiKeys
  has_many :external_durations

  validates :name, presence: true, uniqueness: true
end

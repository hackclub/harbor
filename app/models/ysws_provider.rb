class YswsProvider < ApplicationRecord
  has_many :api_keys, as: :owner
  has_many :external_durations

  validates :name, presence: true, uniqueness: true
end

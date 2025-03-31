class Heartbeat < ApplicationRecord
  before_save :set_fields_hash!

  include Heartbeatable
  include Webhookable

  scope :today, -> { where(time: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :recent, -> { where("created_at > ?", 24.hours.ago) }

  enum :source_type, {
    direct_entry: 0,
    wakapi_import: 1,
    test_entry: 2
  }

  # This is to prevent Rails from trying to use STI even though we have a "type" column
  self.inheritance_column = nil

  belongs_to :user

  validates :time, presence: true

  def self.recent_count
    Rails.cache.fetch("heartbeats_recent_count", expires_in: 5.minutes) do
      recent.count
    end
  end

  def self.recent_imported_count
    Rails.cache.fetch("heartbeats_recent_imported_count", expires_in: 5.minutes) do
      recent.where.not(source_type: :direct_entry).count
    end
  end

  def self.generate_fields_hash(attributes)
    Digest::MD5.hexdigest(attributes.except(*self.unindexed_attributes).to_json)
  end

  def self.unindexed_attributes
    %w[id created_at updated_at source_type fields_hash]
  end

  private

  def set_fields_hash!
    # only if the field exists in activerecord
    if self.class.column_names.include?("fields_hash")
      self.fields_hash = self.class.generate_fields_hash(self.attributes)
    end
  end
end

class Heartbeat < ApplicationRecord
  before_save :set_fields_hash!

  include Heartbeatable

  scope :today, -> { where(time: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :recent, -> { where("created_at > ?", 24.hours.ago) }

  enum :source_type, {
    direct_entry: 0,
    wakapi_import: 1,
    test_entry: 2,
    wakatimecom_import: 3
  }

  enum :ysws_program, {
    nothing: 0,
    high_seas: 1,
    arcade: 2,
    juice: 3,
    onboard: 4,
    sprig: 5,
    cider: 6,
    hackpad: 7,
    boba_drops: 8,
    the_bin: 9,
    blot: 10,
    infill: 11,
    scrapyard: 12,
    hackcraft_mod_edition: 13,
    browser_buddy: 14,
    hackaccino: 15,
    cafe: 16,
    low_skies: 17,
    rasp_api: 18,
    terminal_craft: 19,
    neon: 20,
    jungle: 21,
    counterspell: 22,
    riceathon: 23,
    power_hour: 24,
    scrapyard_flagship: 25,
    ten_days_in_public: 26,
    build_your_own_llm: 27,
    cargo_cult_v2: 28,
    sockathon: 29,
    bakebuild: 30,
    minus_twelve: 31,
    easel: 32,
    retrospect: 33,
    cascade: 34,
    ten_hours_in_public: 35,
    swirl: 36,
    tarot: 37,
    asylum: 38,
    cargo_cult: 39,
    rpg: 40,
    ham_club: 41,
    anchor: 42,
    dessert: 43,
    wizard_orpheus: 44,
    onboard_live: 45,
    say_cheese: 46,
    hackapet: 47,
    clubs_competitions: 48,
    printboard: 49,
    black_box: 50,
    shipwrecked: 51,
    pizza_grant_ysws: 52,
    pixeldust: 53,
    hacklet: 54,
    reflow: 55,
    the_journey: 56,
    visioneer: 57,
    neighborhood: 58
  }, prefix: :claimed_by

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
    %w[id created_at updated_at source_type fields_hash ysws_program]
  end

  private

  def set_fields_hash!
    # only if the field exists in activerecord
    if self.class.column_names.include?("fields_hash")
      self.fields_hash = self.class.generate_fields_hash(self.attributes)
    end
  end
end

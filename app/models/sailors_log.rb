class SailorsLog < ApplicationRecord
  validates :slack_uid, presence: true, uniqueness: true

  before_validation :initialize_projects_summary
  after_create :ensure_notification_preference_for_debug_channel

  belongs_to :user, foreign_key: :slack_uid, primary_key: :slack_uid

  has_many :notification_preferences,
           class_name: "SailorsLogNotificationPreference",
           foreign_key: :slack_uid,
           primary_key: :slack_uid

  has_many :notifications,
           class_name: "SailorsLogSlackNotification",
           foreign_key: :slack_uid,
           primary_key: :slack_uid

  private

  def initialize_projects_summary
    return if projects_summary.present?
    self.projects_summary = Heartbeat.where(user_id: user.id)
                                     .group(:project).duration_seconds
    self.projects_summary ||= {}
  end

  def ensure_notification_preference_for_debug_channel
    return if notification_preferences.any? { |np| np.slack_channel_id == "C0835AZP9GB" && np.enabled }
    notification_preferences.create!(slack_channel_id: "C0835AZP9GB", enabled: true)
  end
end

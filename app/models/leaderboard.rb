class Leaderboard < ApplicationRecord
  has_many :entries,
    class_name: "LeaderboardEntry",
    dependent: :destroy

  validates :start_date, presence: true
  
  enum :period_type, {
    daily: 0,
    weekly: 1
  }

  def finished_generating?
    finished_generating_at.present?
  end
  
  def period_end_date
    if weekly?
      start_date + 6.days
    else
      start_date
    end
  end
  
  def date_range_text
    if weekly?
      "#{start_date.strftime('%b %d')} - #{period_end_date.strftime('%b %d, %Y')}"
    else
      start_date.strftime("%B %d, %Y")
    end
  end
end
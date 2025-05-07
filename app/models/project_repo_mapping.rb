class ProjectRepoMapping < ApplicationRecord
  belongs_to :user

  include PublicActivity::Model
  tracked

  after_save :invalidate_cache

  validates :project_name, presence: true
  validates :repo_url, presence: true
  validates :project_name, uniqueness: { scope: :user_id }

  validates :repo_url, format: {
    with: %r{\A(https?://[^/]+/[^/]+/[^/]+)\z},
    message: "must be a valid repository URL"
  }

  validate :repo_url_exists

  private

  def repo_url_exists
    unless GitRemote.check_remote_exists(repo_url)
      errors.add(:repo_url, "is not cloneable")
    end
  end

  def invalidate_cache
    Rails.cache.delete("user_#{user_id}_project_durations")
  end
end

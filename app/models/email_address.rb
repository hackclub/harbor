class EmailAddress < ApplicationRecord
  belongs_to :user

  validates :email, presence: true,
                   uniqueness: true,
                   format: { with: URI::MailTo::EMAIL_REGEXP }

  enum :source, {
    direct: 0,
    github: 1,
    slack: 2
  }, prefix: true

  before_validation :downcase_email

  private

  def downcase_email
    self.email = email.downcase
  end
end

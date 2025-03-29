class ApiKey < ApplicationRecord
  belongs_to :owner, polymorphic: true

  validates :token, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: { scope: :owner_id }

  before_validation :generate_token!, on: :create

  private

  def generate_token!
    # we need to keep ourselves compatible with WakaTime: https://github.com/wakatime/vscode-wakatime/blob/241b60c8491c14e3c093b1ef2a0276c38586a172/src/utils.ts#L24
    # they use a UUID v4
    self.token ||= SecureRandom.uuid_v4

    # Mark it as something not imported from WakaTime
    self.name ||= "Hackatime key"
  end
end

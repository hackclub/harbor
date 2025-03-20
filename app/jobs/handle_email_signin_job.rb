class HandleEmailSigninJob < ApplicationJob
  queue_as :default

  def perform(email)
    email_address = ActiveRecord::Base.transaction do
      EmailAddress.find_by(email: email) || begin
        user = User.create!
        user.email_addresses.create!(email: email)
      end
    end

    token = email_address.user.create_email_signin_token.token
    LoopsMailer.sign_in_email(email_address.email, token).deliver_now
  end
end

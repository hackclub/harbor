class AuthMailer < ApplicationMailer
  def sign_in_email(email_address, token)
    @token = token
    @user = email_address.user

    mail(
      to: email_address.email,
      subject: "Your Harbor sign-in link"
    )
  end
end

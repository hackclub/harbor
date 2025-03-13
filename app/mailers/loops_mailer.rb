class LoopsMailer < ApplicationMailer
  # Override the default mailer settings to use Loops.so SMTP
  self.delivery_method = :smtp
  self.smtp_settings = {
    address: "smtp.loops.so",
    port: 587,
    user_name: "loops",
    password: ENV["LOOPS_API_KEY"],
    authentication: "plain",
    enable_starttls: true
  }

  def sign_in_email(email_address)
    @email = email_address.email
    @token = email_address.user.create_email_signin_token.token
    @sign_in_url = auth_token_url(@token)

    mail(
      to: @email,
    )
  end
end

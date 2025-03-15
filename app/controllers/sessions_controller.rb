class SessionsController < ApplicationController
  def new
    redirect_uri = url_for(action: :create, only_path: false)
    Rails.logger.info "Starting Slack OAuth flow with redirect URI: #{redirect_uri}"
    redirect_to User.authorize_url(redirect_uri),
                host: "https://slack.com",
                allow_other_host: true
  end

  def create
    redirect_uri = url_for(action: :create, only_path: false)

    if params[:error].present?
      Rails.logger.error "Slack OAuth error: #{params[:error]}"
      redirect_to root_path, alert: "Failed to authenticate with Slack"
      return
    end

    @user = User.from_slack_token(params[:code], redirect_uri)

    if @user&.persisted?
      session[:user_id] = @user.id

      if @user.data_migration_jobs.empty?
        # if they don't have a data migration job, add one to the queue
        OneTime::MigrateUserFromHackatimeJob.perform_later(@user.id)
      end

      redirect_to root_path, notice: "Successfully signed in with Slack!"
    else
      Rails.logger.error "Failed to create/update user from Slack data"
      redirect_to root_path, alert: "Failed to sign in with Slack"
    end
  end

  def email
    email = params[:email].downcase

    # Use a transaction to ensure both user and email are created atomically
    email_address = ActiveRecord::Base.transaction do
      EmailAddress.find_by(email: email) || begin
        user = User.create!
        user.email_addresses.create!(email: email)
      end
    end

    LoopsMailer.sign_in_email(email_address).deliver_later
    redirect_to root_path(sign_in_email: true)
  end

  def token
    valid_token = SignInToken.where(token: params[:token], used_at: nil)
                            .where("expires_at > ?", Time.current)
                            .first

    if valid_token
      valid_token.mark_used!
      session[:user_id] = valid_token.user_id
      redirect_to root_path, notice: "Successfully signed in!"
    else
      redirect_to root_path, alert: "Invalid or expired sign-in link"
    end
  end

  def impersonate
    unless current_user.admin?
      redirect_to root_path, alert: "You are not authorized to impersonate users"
      return
    end

    session[:impersonater_user_id] ||= current_user.id
    user = User.find(params[:id])
    session[:user_id] = user.id
    redirect_to root_path, notice: "Impersonating #{user.username}"
  end

  def stop_impersonating
    session[:user_id] = session[:impersonater_user_id]
    session[:impersonater_user_id] = nil
    redirect_to root_path, notice: "Stopped impersonating"
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Signed out!"
  end
end

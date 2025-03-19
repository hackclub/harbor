class User < ApplicationRecord
  has_paper_trail
  encrypts :slack_access_token, :github_access_token

  validates :slack_uid, uniqueness: true, allow_nil: true
  validates :github_uid, uniqueness: true, allow_nil: true
  validates :timezone, inclusion: { in: TZInfo::Timezone.all.map(&:identifier) }, allow_nil: false

  has_many :heartbeats
  has_many :email_addresses
  has_many :sign_in_tokens
  has_many :project_repo_mappings

  has_many :hackatime_heartbeats,
    foreign_key: :user_id,
    primary_key: :slack_uid,
    class_name: "Hackatime::Heartbeat"

  has_many :project_labels,
    foreign_key: :user_id,
    primary_key: :slack_uid,
    class_name: "Hackatime::ProjectLabel"

  has_many :api_keys

  enum :hackatime_extension_text_type, {
    simple_text: 0,
    clock_emoji: 1,
    compliment_text: 2
  }

  after_save :invalidate_activity_graph_cache, if: :saved_change_to_timezone?

  def data_migration_jobs
    GoodJob::Job.where(
      "serialized_params->>'arguments' LIKE ?", "%#{id}%"
    ).where(
      "job_class = ?", "OneTime::MigrateUserFromHackatimeJob"
    ).order(created_at: :desc).limit(10).all
  end

  def format_extension_text(duration)
    case hackatime_extension_text_type
    when "simple_text"
      return "Start coding to track your time" if duration.zero?
      ::ApplicationController.helpers.short_time_simple(duration)
    when "clock_emoji"
      ::ApplicationController.helpers.time_in_emoji(duration)
    when "compliment_text"
      FlavorText.compliment.sample
    end
  end

  def set_timezone_from_slack
    return unless slack_uid.present?

    user_response = HTTP.auth("Bearer #{slack_access_token}")
      .get("https://slack.com/api/users.info?user=#{slack_uid}")

    user_data = JSON.parse(user_response.body.to_s)

    return unless user_data["ok"]

    timezone_string = user_data.dig("user", "tz")

    return unless timezone_string.present?

    parse_and_set_timezone(timezone_string)
  end

  def parse_and_set_timezone(timezone)
    begin
      tz = ActiveSupport::TimeZone.find_tzinfo(timezone)
      self.timezone = tz.name
    rescue TZInfo::InvalidTimezoneIdentifier => e
      Rails.logger.error "Invalid timezone #{timezone} for user #{id}: #{e.message}"
    end
  end

  def admin?
    is_admin
  end

  def make_admin!
    update!(is_admin: true)
  end

  def remove_admin!
    update!(is_admin: false)
  end

  def update_slack_status
    return unless uses_slack_status?

    # check if the user already has a custom status set– if it doesn't look like
    # our format, don't clobber it

    current_status_response = HTTP.auth("Bearer #{slack_access_token}")
      .get("https://slack.com/api/users.profile.get")

    current_status = JSON.parse(current_status_response.body.to_s)

    custom_status_regex = /spent on \w+ today$/
    status_present = current_status.dig("profile", "status_text").present?
    status_custom = !current_status.dig("profile", "status_text").match?(custom_status_regex)

    return if status_present && status_custom

    current_project = heartbeats.order(time: :desc).first&.project
    current_project_heartbeats = heartbeats.today.where(project: current_project)
    current_project_duration = Heartbeat.duration_seconds(current_project_heartbeats)
    current_project_duration_formatted = Heartbeat.duration_simple(current_project_heartbeats)

    # for 0 duration, don't set a status – this will let status expire when the user has not been cooking today
    return if current_project_duration.zero?

    status_emoji =
      case current_project_duration
      when 0...30.minutes
        %w[thinking cat-on-the-laptop loading-tumbleweed rac-yap]
      when 30.minutes...1.hour
        %w[working-parrot meow_code]
      when 1.hour...2.hours
        %w[working-parrot meow-code]
      when 2.hours...3.hours
        %w[working-parrot cat-typing bangbang]
      when 3.hours...5.hours
        %w[cat-typing meow-code laptop-fire bangbang]
      when 5.hours...8.hours
        %w[cat-typing laptop-fire hole-mantelpiece_clock keyboard-fire bangbang bangbang]
      when 8.hours...15.hours
        %w[laptop-fire bangbang bangbang rac_freaking rac_freaking hole-mantelpiece_clock]
      when 15.hours...20.hours
        %w[bangbang bangbang rac_freaking hole-mantelpiece_clock]
      else
        %w[areyousure time-to-stop]
      end.sample

    status_emoji = ":#{status_emoji}:"
    status_text = "#{current_project_duration_formatted} spent on #{current_project} today"

    # Update the user's status
    HTTP.auth("Bearer #{slack_access_token}")
      .post("https://slack.com/api/users.profile.set", form: {
        profile: {
          status_text:,
          status_emoji:,
          status_expiration: (Time.now + 10.minutes).to_i
        }
      })
  end

  def self.authorize_url(redirect_uri)
    params = {
      client_id: ENV["SLACK_CLIENT_ID"],
      redirect_uri: redirect_uri,
      state: SecureRandom.hex(24),
      user_scope: "users.profile:read,users.profile:write,users:read,users:read.email"
    }

    URI.parse("https://slack.com/oauth/v2/authorize?#{params.to_query}")
  end

  def self.github_authorize_url(redirect_uri)
    params = {
      client_id: ENV["GITHUB_CLIENT_ID"],
      redirect_uri: redirect_uri,
      state: SecureRandom.hex(24),
      scope: "user:email"
    }

    URI.parse("https://github.com/login/oauth/authorize?#{params.to_query}")
  end

  def self.from_slack_token(code, redirect_uri)
    # Exchange code for token
    response = HTTP.post("https://slack.com/api/oauth.v2.access", form: {
      client_id: ENV["SLACK_CLIENT_ID"],
      client_secret: ENV["SLACK_CLIENT_SECRET"],
      code: code,
      redirect_uri: redirect_uri
    })

    data = JSON.parse(response.body.to_s)

    return nil unless data["ok"]

    # Get user info
    user_response = HTTP.auth("Bearer #{data['authed_user']['access_token']}")
      .get("https://slack.com/api/users.info?user=#{data['authed_user']['id']}")

    user_data = JSON.parse(user_response.body.to_s)

    return nil unless user_data["ok"]

    email = user_data.dig("user", "profile", "email")
    email_address = EmailAddress.find_or_initialize_by(email: email)
    user = email_address.user
    user ||= begin
      u = User.find_or_initialize_by(slack_uid: data.dig("authed_user", "id"))
      u.email_addresses << email_address
      u
    end

    user.slack_uid = data.dig("authed_user", "id")

    user.username ||= user_data.dig("user", "profile", "username")
    user.username ||= user_data.dig("user", "profile", "display_name_normalized")
    user.slack_avatar_url = user_data.dig("user", "profile", "image_192") || user_data.dig("user", "profile", "image_72")

    user.parse_and_set_timezone(user_data.dig("user", "tz"))

    user.slack_access_token = data["authed_user"]["access_token"]
    user.slack_scopes = data["authed_user"]["scope"]&.split(/,\s*/)

    user.save!
    user
  rescue => e
    Rails.logger.error "Error creating user from Slack data: #{e.message}"
    nil
  end

  def self.from_github_token(code, redirect_uri, current_user = nil)
    # Exchange code for token
    response = HTTP.headers(accept: "application/json")
      .post("https://github.com/login/oauth/access_token", form: {
        client_id: ENV["GITHUB_CLIENT_ID"],
        client_secret: ENV["GITHUB_CLIENT_SECRET"],
        code: code,
        redirect_uri: redirect_uri
      })

    data = JSON.parse(response.body.to_s)
    Rails.logger.info "GitHub OAuth response: #{data.inspect}"
    return nil unless data["access_token"]

    # Get user info
    user_response = HTTP.auth("Bearer #{data['access_token']}")
      .get("https://api.github.com/user")

    user_data = JSON.parse(user_response.body.to_s)
    Rails.logger.info "GitHub user data: #{user_data.inspect}"
    Rails.logger.info "GitHub user ID type: #{user_data['id'].class}"

    # Get user email from profile
    primary_email = user_data["email"]
    return nil unless primary_email

    # If we have a current user, update that user
    if current_user
      user = current_user
    else
      # For new sign-ins, try to find user by GitHub ID or email
      user = User.find_by(github_uid: user_data["id"])
      unless user
        email_address = EmailAddress.find_by(email: primary_email)
        user = email_address&.user
      end
      # If still no user found, create a new one
      user ||= begin
        u = User.new
        u.email_addresses << EmailAddress.new(email: primary_email)
        u
      end
    end

    # Update GitHub-specific fields
    user.github_uid = user_data["id"]
    user.username ||= user_data["login"]
    user.github_username = user_data["login"]
    user.github_avatar_url = user_data["avatar_url"]
    user.github_access_token = data["access_token"]

    # Add the GitHub email if it's not already associated
    unless user.email_addresses.exists?(email: primary_email)
      begin
        user.email_addresses << EmailAddress.new(email: primary_email)
      rescue ActiveRecord::RecordInvalid => e
        # If the email already exists for another user, we can ignore it
        Rails.logger.info "Email #{primary_email} already exists for another user"
      end
    end

    user.save!
    user
  rescue => e
    Rails.logger.error "Error creating user from GitHub data: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def avatar_url
    return self.slack_avatar_url if self.slack_avatar_url.present?
    return self.github_avatar_url if self.github_avatar_url.present?
    initials = self.email_addresses&.first&.email[0..1]&.upcase
    hashed_initials = Digest::SHA256.hexdigest(initials)[0..5]
    "https://i2.wp.com/ui-avatars.com/api/#{initials}/48/#{hashed_initials}/fff?ssl=1" if initials.present?
  end

  def display_name
    return username if username.present?

    # "zach@hackclub.com" -> "zach (email sign-up)"
    email = email_addresses&.first&.email
    return "error displaying name" unless email.present?

    email.split("@")&.first + " (email sign-up)"
  end

  def project_names
    heartbeats.select(:project).distinct.pluck(:project)
  end

  def active_project
    most_recent_direct_entry_heartbeat&.project
  end

  def active_project_duration
    return nil unless active_project

    heartbeats.where(project: active_project).duration_seconds
  end

  def most_recent_direct_entry_heartbeat
    heartbeats.where(source_type: :direct_entry).order(time: :desc).first
  end

  def create_email_signin_token
    sign_in_tokens.create!(auth_type: :email)
  end

  def find_valid_token(token)
    sign_in_tokens.valid.find_by(token: token)
  end

  private

  def invalidate_activity_graph_cache
    Rails.cache.delete("user_#{id}_daily_durations")
  end
end

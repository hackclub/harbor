class SlackController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_slack_request

  # allow usage of short_time_simple
  include ApplicationHelper
  helper_method :short_time_simple

  # Handle slack commands
  def create
    # Acknowledge receipt
    render json: {
      response_type: "ephemeral",
      blocks: [
        {
          type: "context",
          elements: [
            {
              type: "mrkdwn",
              text: "#{params_hash[:command]} #{params_hash[:text]}"
            }
          ]
        }
      ]
    }

    case params_hash[:command].gsub("/", "").downcase
    when "sailorslog"
      SlackCommand::SailorsLogJob.perform_later(params_hash)
    end
  end

  private

  def params_hash
    params.permit(:command, :text, :response_url, :user_id, :team_id, :team_domain, :channel_id, :channel_name, :user_name, :trigger_word).to_h
  end

  def verify_slack_request
    timestamp = request.headers["X-Slack-Request-Timestamp"]
    signature = request.headers["X-Slack-Signature"]

    # Skip verification in development
    return true if Rails.env.development?

    # if coming from /sailorslog, use sailors_log_signing_secret
    # if coming from /timedump, use slack_signing_secret
    signing_secret = params_hash[:command].include?("sailorslog") ? ENV["SAILORS_LOG_SLACK_SIGNING_SECRET"] : ENV["SLACK_SIGNING_SECRET"]

    sig_basestring = "v0:#{timestamp}:#{request.raw_post}"

    # Try both signing secrets
    signature = "v0=" + OpenSSL::HMAC.hexdigest(
      "SHA256",
      signing_secret,
      sig_basestring
    )

    # Check if the request matches signature
    unless ActiveSupport::SecurityUtils.secure_compare(signature, signature)
      head :unauthorized
      nil
    end
  end
end

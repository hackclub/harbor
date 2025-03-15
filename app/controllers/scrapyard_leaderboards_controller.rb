class ScrapyardLeaderboardsController < ApplicationController
  # March 14, 2024 at 8:00 PM Eastern
  TRACKING_START_TIME = Time.find_zone("Eastern Time (US & Canada)").local(2025, 3, 14, 20, 0).to_i

  def index
    # Get all attendees and their emails in one query
    event_attendees = Warehouse::ScrapyardLocalAttendee
      .where.not(email: nil)
      .group_by(&:event_id)

    # Only get events that have attendees
    @events = Warehouse::ScrapyardEvent
      .where(id: event_attendees.keys)
      .order(created_at: :desc)

    # Pre-fetch all users for the emails we have
    all_emails = event_attendees.values.flatten.map(&:email).compact
    email_to_user = EmailAddress.where(email: all_emails).includes(:user).index_by(&:email)

    # For each event, get the total coding time of its attendees
    @event_stats = @events.map do |event|
      # Get attendees for this event
      attendees = event_attendees[event.id] || []
      users = attendees
        .map { |a| email_to_user[a.email]&.user }
        .compact
        .uniq

      # Calculate total duration for all users in one query
      total_seconds = if users.any?
        Heartbeat
          .where(user: users)
          .where("time >= ?", TRACKING_START_TIME)
          .duration_seconds
      else
        0
      end

      {
        event: event,
        total_seconds: total_seconds,
        attendee_count: users.count,
        average_seconds_per_attendee: users.any? ? (total_seconds.to_f / users.count) : 0
      }
    end

    # filter out events with no users
    @event_stats = @event_stats.select { |stats| stats[:attendee_count] > 0 }

    # Sort by total coding time
    @event_stats = @event_stats.sort_by { |stats| -stats[:total_seconds] }
  end

  def show
    @event = Warehouse::ScrapyardEvent.find(params[:id])

    # Get attendees and their emails
    attendees = Warehouse::ScrapyardLocalAttendee
      .where.not(email: nil)
      .for_event(@event)
      .uniq { |attendee| attendee.email }

    # Pre-fetch all users for the emails we have
    emails = attendees.map(&:email).compact
    email_to_user = EmailAddress.where(email: emails).includes(:user).index_by(&:email)

    # Create a map of email to attendee for looking up preferred names
    email_to_attendee = attendees.index_by(&:email)

    # Map attendees to users while keeping track of the original attendee
    user_attendees = attendees.map do |attendee|
      {
        user: email_to_user[attendee.email]&.user,
        attendee: attendee
      }
    end.select { |ua| ua[:user].present? }

    # Get all heartbeats for all users in one query
    users = user_attendees.map { |ua| ua[:user] }
    user_heartbeats = Heartbeat
      .where(user: users)
      .where("time >= ?", TRACKING_START_TIME)
      .group(:user_id)
      .duration_seconds

    # Map the results
    @attendee_stats = user_attendees.map do |ua|
      email = ua[:attendee].email if Rails.env.development?
      {
        user: ua[:user],
        display_name: ua[:user].username || ua[:attendee].preferred_name || "Anonymous",
        total_seconds: user_heartbeats[ua[:user].id] || 0,
        email: email || nil
      }
    end

    # Sort by total coding time
    @attendee_stats = @attendee_stats.sort_by { |stats| -stats[:total_seconds] }
  end
end

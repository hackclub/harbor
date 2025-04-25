class ScrapyardLeaderboardsController < ApplicationController
  # March 14, 2024 at 8:00 PM Eastern
  TRACKING_START_TIME = Time.find_zone("Eastern Time (US & Canada)").local(2025, 3, 14, 20, 0).to_i
  TRACKING_END_TIME = Time.find_zone("Eastern Time (US & Canada)").local(2025, 3, 17, 20, 0).to_i
  PINNED_EVENT_TIMEOUT = 1.minutes

  helper_method :is_watched?

  def index
    @sort_by = params[:sort] == "average" ? "average" : "total"

    # If there's a pinned event, cache it
    if params[:event_pin].present?
      mark_event_as_pinned(params[:event_pin])
    end

    # Cache the expensive computations for 10 seconds
    @event_stats = Rails.cache.fetch("scrapyard_leaderboard_stats", expires_in: 10.seconds) do
      # Get all attendees and their emails in one query
      event_attendees = Warehouse::Scrapyard::LocalAttendee
        .where.not(email: nil)
        .group_by(&:event_id)

      # Only get events that have attendees
      events = Warehouse::Scrapyard::LocalEvent
        .where(id: event_attendees.keys)
        .order(created_at: :desc)

      # Pre-fetch all users for the emails we have
      all_emails = event_attendees.values.flatten.map(&:email).compact
      email_to_user = EmailAddress.where(email: all_emails).includes(:user).index_by(&:email)

      # For each event, get the total coding time of its attendees
      event_stats = events.map do |event|
        # Get attendees for this event
        attendees = event_attendees[event.id] || []
        users = attendees
          .map { |a| email_to_user[a.email]&.user }
          .compact
          .uniq

        # Calculate total duration for all users in one query
        total_seconds = if users.any?
          Heartbeat.where(user: users)
                   .where("time >= ?", TRACKING_START_TIME)
                   .where("time <= ?", TRACKING_END_TIME)
                   .group(:user_id)
                   .duration_seconds
                   .values
                   .sum
        else
          0
        end

        {
          event: event,
          total_seconds: total_seconds,
          hackatime_users: users.count,
          total_attendees: attendees.count,
          average_seconds_per_attendee: users.any? ? (total_seconds.to_f / users.count) : 0
        }
      end

      # filter out events with no users
      event_stats.select { |stats| stats[:hackatime_users] > 0 }
    end

    # Sort by selected metric (do this outside cache since it depends on params)
    @event_stats = @event_stats.sort_by do |stats|
      if @sort_by == "average"
        -stats[:average_seconds_per_attendee]
      else
        -stats[:total_seconds]
      end
    end
  end

  def pin
    event_id = params[:id]
    mark_event_as_pinned(event_id)
    head :ok
  end

  def show
    @event = Warehouse::Scrapyard::LocalEvent.find(params[:id])

    @attendee_stats = Rails.cache.fetch("scrapyard_leaderboard_event_#{@event.id}", expires_in: 10.seconds) do
      attendees = Warehouse::Scrapyard::LocalAttendee
        .where.not(email: nil)
        .for_event(@event)
        .uniq { |attendee| attendee.email }

      emails = attendees.map(&:email).compact
      email_to_user = EmailAddress.where(email: emails).includes(:user).index_by(&:email)

      user_attendees = attendees.map do |attendee|
        {
          user: email_to_user[attendee.email]&.user,
          attendee: attendee
        }
      end.select { |ua| ua[:user].present? }

      users = user_attendees.map { |ua| ua[:user] }
      user_heartbeats = Heartbeat
        .where(user: users)
        .where("time >= ?", TRACKING_START_TIME)
        .where("time <= ?", TRACKING_END_TIME)
        .group(:user_id)
        .duration_seconds

      stats = user_attendees.map do |ua|
        email = ua[:attendee].email if Rails.env.development?
        {
          user: ua[:user],
          display_name: ua[:user].username || ua[:attendee].preferred_name || "Anonymous",
          total_seconds: user_heartbeats[ua[:user].id] || 0,
          email: email || nil
        }
      end

      stats.sort_by { |stats| -stats[:total_seconds] }
    end
  end

  private

  def mark_event_as_pinned(event_id)
    Rails.cache.write(
      "pinned_event:#{event_id}",
      true,
      expires_in: PINNED_EVENT_TIMEOUT
    )
  end

  def is_watched?(event_id)
    Rails.cache.exist?("pinned_event:#{event_id}")
  end
end

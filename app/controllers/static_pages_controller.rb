class StaticPagesController < ApplicationController
  def index
    @leaderboard = Leaderboard.where.associated(:entries)
                              .where(start_date: Date.current)
                              .where(deleted_at: nil)
                              .where(period_type: :daily)
                              .distinct
                              .first

    if current_user
      flavor_texts = FlavorText.motto + FlavorText.conditional_mottos(current_user)
      flavor_texts += FlavorText.rare_motto if Random.rand(10) < 1
      @flavor_text = flavor_texts.sample

      unless params[:date].blank?
        # implement this later– for now just redirect to a random video
        allowed_hosts = FlavorText.random_time_video.map { |v| URI.parse(v).host }
        redirect_to FlavorText.random_time_video.sample, allow_other_host: allowed_hosts
      end

      @show_wakatime_setup_notice = current_user.heartbeats.empty?
      @setup_social_proof = get_setup_social_proof if @show_wakatime_setup_notice

      # Get languages and editors in a single query using window functions
      results = current_user.heartbeats.today
        .select(
          :language,
          :editor,
          "COUNT(*) OVER (PARTITION BY language) as language_count",
          "COUNT(*) OVER (PARTITION BY editor) as editor_count"
        )
        .distinct
        .to_a

      # Process results to get sorted languages and editors
      language_counts = results
        .map { |r| [ r.language, r.language_count ] }
        .reject { |lang, _| lang.nil? || lang.empty? }
        .uniq
        .sort_by { |_, count| -count }

      editor_counts = results
        .map { |r| [ r.editor, r.editor_count ] }
        .reject { |ed, _| ed.nil? || ed.empty? }
        .uniq
        .sort_by { |_, count| -count }

      @todays_languages = language_counts.map(&:first)
      @todays_editors = editor_counts.map(&:first)
      @show_logged_time_sentence = @todays_languages.any? || @todays_editors.any?
    else
      @social_proof ||= begin
        # Only run queries as needed, starting with the smallest time range
        if (in_past_hour = Heartbeat.where("time > ?", 1.hour.ago.to_f).distinct.count(:user_id)) > 5
          "In the past hour, #{in_past_hour} Hack Clubbers have coded with Hackatime."
        elsif (in_past_day = Heartbeat.where("time > ?", 1.day.ago.to_f).distinct.count(:user_id)) > 5
          "In the past day, #{in_past_day} Hack Clubbers have coded with Hackatime."
        elsif (in_past_week = Heartbeat.where("time > ?", 1.week.ago.to_f).distinct.count(:user_id)) > 5
          "In the past week, #{in_past_week} Hack Clubbers have coded with Hackatime."
        end
      end

      @home_stats = Rails.cache.read("home_stats")
      CacheHomeStatsJob.perform_later if @home_stats.nil?
    end
  end

  def project_durations
    return unless current_user

    @project_repo_mappings = current_user.project_repo_mappings

    project_durations = Rails.cache.fetch("user_#{current_user.id}_project_durations", expires_in: 1.minute) do
      project_times = current_user.heartbeats.group(:project).duration_seconds
      project_labels = current_user.project_labels

      project_times.map do |project, duration|
        {
          project: project_labels.find { |p| p.project_key == project }&.label || project || "Unknown",
          repo_url: @project_repo_mappings.find { |p| p.project_name == project }&.repo_url,
          duration: duration
        }
      end.filter { |p| p[:duration].positive? }.sort_by { |p| p[:duration] }.reverse
    end

    render partial: "project_durations", locals: { project_durations: project_durations }
  end

  def activity_graph
    return unless current_user

    daily_durations = Rails.cache.fetch("user_#{current_user.id}_daily_durations", expires_in: 1.minute) do
      # Set the timezone for the duration of this request
      Time.use_zone(current_user.timezone) do
        current_user.heartbeats.daily_durations.to_h
      end
    end

    # Consider 8 hours as a "full" day of coding
    length_of_busiest_day = 8.hours.to_i  # 28800 seconds

    render partial: "activity_graph", locals: {
      daily_durations: daily_durations,
      length_of_busiest_day: length_of_busiest_day
    }
  end


  def currently_hacking
    # Get all users who have heartbeats in the last 15 minutes
    users = Rails.cache.fetch("currently_hacking", expires_in: 1.minute) do
      user_ids = Heartbeat.where("time > ?", 5.minutes.ago.to_f)
                          .distinct
                          .pluck(:user_id)

      User.where(id: user_ids)
    end

    render partial: "currently_hacking", locals: { users: users }
  end

  def 🃏
    redirect_to root_path unless current_user&.slack_uid

    record = HTTP.auth("Bearer #{ENV.fetch("WILDCARD_AIRTABLE_KEY")}").patch("https://api.airtable.com/v0/appt3yVn2nbiUaijm/tblRCAMjfQ4MIsMPp",
      json: {
        records: [
          {
            fields: {
              slack_id: current_user.slack_uid
            }
          }
        ],
        performUpsert: {
          fieldsToMergeOn: [ "slack_id" ]
        }
      }
    )
    record_data = JSON.parse(record.body)

    record_id = record_data.dig("records", 0, "id")

    redirect_to root_path unless record_id&.present?

    # if record is created, set a new auth_key:
    auth_key = SecureRandom.hex(16)
    HTTP.auth("Bearer #{ENV.fetch("WILDCARD_AIRTABLE_KEY")}").patch("https://api.airtable.com/v0/appt3yVn2nbiUaijm/tblRCAMjfQ4MIsMPp",
      json: {
        records: [
          { id: record_id, fields: { auth_key: auth_key } }
        ]
      }
    )

    wildcard_host = ENV.fetch("WILDCARD_HOST")

    redirect_to "#{wildcard_host}?auth_key=#{auth_key}", allow_other_host: wildcard_host
  end

  private

  def get_setup_social_proof
    # Count users who set up in different time periods
    social_proof_for_time_period(5.minutes.ago, 1, "in the last 5 minutes") ||
      social_proof_for_time_period(1.hour.ago, 3, "in the last hour") ||
      social_proof_for_time_period(1.day.ago, 5, "today") ||
      social_proof_for_time_period(1.week.ago, 5, "in the past week") ||
      social_proof_for_time_period(1.month.ago, 5, "in the past month") ||
      social_proof_for_time_period(Time.current.beginning_of_year, 5, "this year")
  end

  def social_proof_for_time_period(time_period, threshold, humanized_time_period)
    count_unique = Heartbeat.where("time > ?", time_period.to_f)
                            .where(source_type: :test_entry)
                            .distinct.count(:user_id)

    return nil if count_unique < threshold

    "#{count_unique.to_s + ' Hack Clubber'.pluralize(count_unique)} set up Hackatime #{humanized_time_period}"
  end
end

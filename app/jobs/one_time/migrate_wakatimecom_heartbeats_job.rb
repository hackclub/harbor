require "fileutils"
require "open-uri"

class OneTime::MigrateWakatimecomHeartbeatsJob < ApplicationJob
  queue_as :default

  include GoodJob::ActiveJobExtensions::Concurrency

  # only allow one instance of this job to run at a time
  good_job_control_concurrency_with(
    key: -> { "migrate_wakatimecom_heartbeats_job_#{arguments.first}" },
    total_limit: 1,
  )

  def perform(user_id)
    @user = User.find(user_id)
    import_heartbeats
  end

  private

  def import_heartbeats
    puts "starting wakatime.com heartbeats import for user #{@user.id}"

    # get dump once to check if there's already one.
    # in development i've already created one and don't want to keep spamming dumps
    # (it's also really slow for me, my entire coding career is in there)
    dump = get_dumps

    if dump.empty?
      create_dump
      while true
        sleep 5
        dump = get_dumps
        puts "wakatime.com import for #{@user.id} is at #{dump['percent_complete']}%"
        break unless dump.empty?
      end
    end

    output_dir = Rails.root.join('storage', 'wakatime_dumps')
    FileUtils.mkdir_p(output_dir)
    output_path = output_dir.join("wakatime_heartbeats_#{@user.id}.json")

    puts "downloading wakatime.com heartbeats dump for user #{@user.id}"
    auth_token = Base64.strict_encode64("#{@user.wakatime_api_key}:")
    
    File.open(output_path, 'wb') do |file|
      # i don't get why with HTTP it doesn't work...
      file.write(URI.open(dump['download_url']).read)
    end
    
    puts "wakatime.com heartbeats saved to #{output_path} for user #{@user.id}"
  end

  def get_dumps
    auth_token = Base64.strict_encode64("#{@user.wakatime_api_key}:")
    response = HTTP.auth("Basic #{auth_token}")
      .get('https://api.wakatime.com/api/v1/users/current/data_dumps')

    if response.status.success?
      dumps = JSON.parse(response.body)['data'].find { |dump| dump['type'] == 'heartbeats' && dump['status'] == 'Completed' }
      return dumps || {}
    else
      puts "Failed to fetch Wakatime.com data dumps: #{response.status} - #{response.body}"
      return {}
    end
  end

  def create_dump
    auth_token = Base64.strict_encode64("#{@user.wakatime_api_key}:")
    response = HTTP.auth("Basic #{auth_token}")
      .post('https://api.wakatime.com/api/v1/users/current/data_dumps',
        json: {
          type: 'heartbeats',
          email_when_finished: false,
        }
      )
  end
end
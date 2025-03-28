class OneTime::BackfillHeartbeatEditorJob < ApplicationJob
  queue_as :default

  def perform(dry_run = true)
    puts "Processing heartbeats" if dry_run
    Heartbeat.where(editor: nil).where.not(user_agent: nil).find_each do |heartbeat|
      parsed_ua = WakatimeService.new.parse_user_agent(heartbeat.user_agent)
      if parsed_ua[:err].present?
        puts "Error parsing user agent for heartbeat #{heartbeat.id}, user_agent: #{heartbeat.user_agent}, error: #{parsed_ua[:err]}"
        next
      end
      puts "Processing heartbeat #{heartbeat.id}, user_agent: #{heartbeat.user_agent}, editor: #{parsed_ua[:editor]}, os: #{parsed_ua[:os]}" if dry_run
      next if dry_run
      heartbeat.update(editor: parsed_ua[:editor], operating_system: parsed_ua[:os])
    end
  end
end

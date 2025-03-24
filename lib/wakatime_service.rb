include ApplicationHelper

class WakatimeService
  def initialize(user = nil, specific_filters = {}, allow_cache = true)
    @scope = Heartbeat.all
    @user = user

    @scope = @scope.where(user_id: @user.id) if @user.present?

    @specific_filters = specific_filters
    @allow_cache = allow_cache
  end

  def generate_summary
    summary = {}

    summary[:username] = @user.username if @user.present?
    summary[:user_id] = @user.id.to_s if @user.present?
    summary[:is_coding_activity_visible] = true if @user.present?
    summary[:is_other_usage_visible] = true if @user.present?
    summary[:status] = "ok"

    @start_time = @scope.minimum(:time)
    @end_time = @scope.maximum(:time)
    summary[:start] = Time.at(@start_time).strftime("%Y-%m-%dT%H:%M:%SZ")
    summary[:end] = Time.at(@end_time).strftime("%Y-%m-%dT%H:%M:%SZ")

    summary[:range] = "all_time"
    summary[:human_readable_range] = "All Time"

    @total_seconds = @scope.duration_seconds
    summary[:total_seconds] = @total_seconds

    @total_days = (@end_time - @start_time) / 86400
    summary[:daily_average] = @total_seconds / @total_days

    summary[:human_readable_total] = ApplicationController.helpers.short_time_detailed(@total_seconds)
    summary[:human_readable_daily_average] = ApplicationController.helpers.short_time_detailed(summary[:daily_average])

    summary[:languages] = generate_summary_chunk(:language) if @specific_filters[:languages]
    summary[:projects] = generate_summary_chunk(:project) if @specific_filters[:projects]
    summary[:editors] = generate_summary_chunk(:editor) if @specific_filters[:editors]
    summary[:operating_systems] = generate_summary_chunk(:operating_system) if @specific_filters[:operating_systems]

    summary
  end

  def generate_summary_chunk(group_by)
    result = []
    @scope.group(group_by).duration_seconds.each do |key, value|
      normalized_name = if group_by == :editor
        normalize_editor(key)
      elsif group_by == :operating_system
        normalize_os(key)
      else
        key.presence || "Other"
      end

      result << {
        name: normalized_name,
        total_seconds: value,
        text: ApplicationController.helpers.short_time_simple(value),
        hours: value / 3600,
        minutes: (value % 3600) / 60,
        percent: (100.0 * value / @total_seconds).round(2),
        digital: ApplicationController.helpers.digital_time(value)
      }
    end
    result.sort_by { |item| -item[:total_seconds] }.first(10)
  end

  def normalize_editor(editor)
    return "Unknown" if editor.blank?
    
    editor_name = editor.to_s.downcase
    
    case editor_name
    when /vs ?code/i, /visual studio code/i
      "VS Code"
    when /intellij/i
      "IntelliJ IDEA"
    when /pycharm/i
      "PyCharm"
    when /webstorm/i
      "WebStorm"
    when /phpstorm/i
      "PhpStorm"
    when /rubymine/i
      "RubyMine"
    when /android studio/i
      "Android Studio"
    when /xcode/i
      "Xcode"
    when /atom/i
      "Atom"
    when /sublime/i
      "Sublime Text"
    when /vim/i, /neovim/i, /nvim/i
      "Vim/NeoVim"
    when /emacs/i
      "Emacs"
    when /notepad\+\+/i
      "Notepad++"
    when /textmate/i
      "TextMate"
    when /eclipse/i
      "Eclipse"
    when /netbeans/i
      "NetBeans"
    when /brackets/i
      "Brackets"
    when /coda/i
      "Coda"
    when /nova/i
      "Nova"
    when /bbedit/i
      "BBEdit"
    when /dreamweaver/i
      "Dreamweaver"
    when /replit/i, /repl\.it/i
      "Replit"
    when /codesandbox/i
      "CodeSandbox"
    when /codepen/i
      "CodePen"
    when /glitch/i
      "Glitch"
    when /googledocs/i, /google docs/i
      "Google Docs"
    when /msword/i, /microsoft word/i
      "Microsoft Word"
    when /excel/i
      "Microsoft Excel"
    when /powerpoint/i
      "Microsoft PowerPoint"
    when /outlook/i
      "Microsoft Outlook"
    when /terminal/i, /zsh/i, /bash/i, /sh$/i, /fish/i
      "Terminal"
    else
      # Return the original with proper capitalization
      editor
    end
  end

  def normalize_os(os)
    return "Unknown" if os.blank?
    
    os_name = os.to_s.downcase
    
    case os_name
    when /darwin/i, /mac/i, /macos/i, /os x/i
      "macOS"
    when /win/i, /windows/i
      "Windows"
    when /linux/i
      if os_name =~ /ubuntu/i
        "Ubuntu"
      elsif os_name =~ /debian/i
        "Debian"
      elsif os_name =~ /fedora/i
        "Fedora"
      elsif os_name =~ /centos/i
        "CentOS"
      elsif os_name =~ /red ?hat/i, /rhel/i
        "Red Hat"
      elsif os_name =~ /arch/i
        "Arch Linux"
      elsif os_name =~ /mint/i
        "Linux Mint"
      elsif os_name =~ /manjaro/i
        "Manjaro"
      elsif os_name =~ /elementary/i
        "Elementary OS"
      elsif os_name =~ /pop!?_?os/i
        "Pop!_OS"
      elsif os_name =~ /kali/i
        "Kali Linux"
      else
        "Linux"
      end
    when /android/i
      "Android"
    when /ios/i, /iphone/i, /ipad/i
      "iOS"
    when /chrome ?os/i, /chromium ?os/i
      "ChromeOS"
    when /bsd/i
      if os_name =~ /free/i
        "FreeBSD"
      elsif os_name =~ /open/i
        "OpenBSD"
      elsif os_name =~ /net/i
        "NetBSD"
      else
        "BSD"
      end
    when /solaris/i, /sunos/i
      "Solaris"
    when /aix/i
      "AIX"
    when /hp-?ux/i
      "HP-UX"
    when /irix/i
      "IRIX"
    when /vms/i
      "VMS"
    when /z ?os/i
      "z/OS"
    when /os\/2/i
      "OS/2"
    when /amiga/i
      "AmigaOS"
    when /nintendos/i, /nintendo switch/i
      "Nintendo Switch"
    when /playstation/i, /ps[345]/i
      "PlayStation"
    when /xbox/i
      "Xbox"
    else
      # Return the original with proper capitalization
      os
    end
  end
end
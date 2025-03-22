class NameNormalizerService
  def self.normalize_editor(name)
    return "Unknown" if name.blank?

    name_lower = name.to_s.downcase

    case name_lower
    when "vs code", "vscode", "visual studio code"
      "VSCode"
    when "windowspowershell"
      "PowerShell"
    when "wsl"
      "WSL"
    when "jetbrains rider"
      "Rider"
    when "intellij idea"
      "IntelliJ IDEA"
    when "android studio"
      "Android Studio"
    when "sublime_text", "sublime text"
      "Sublime Text"
    when "text"
      "Text Editor"
    else
      # Return proper capitalization for other editors
      name.to_s.split(/[\s_-]/).map(&:capitalize).join("")
    end
  end

  # Normalize operating system names for consistent display
  def self.normalize_os(name)
    return "Unknown" if name.blank?

    # Convert to lowercase for case-insensitive matching
    name_lower = name.to_s.downcase

    case name_lower
    when "darwin", "mac", "macos"
      "macOS"
    when "windows", "win32"
      "Windows"
    when "linux-gnu", "linux", "ubuntu", "debian"
      "Linux"
    when "wsl", "windows_wsl"
      "WSL"
    when "windowspowershell"
      "PowerShell"
    else
      # Return the original name with proper capitalization
      name.to_s
    end
  end
end

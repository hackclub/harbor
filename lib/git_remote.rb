require "open3"

class GitRemote
  def self.check_remote_exists(repo_url)
    safe_repo_url = URI.parse(repo_url).to_s.gsub(" ", "").gsub("'", "")
    Open3.capture2e("git", "ls-remote", safe_repo_url).last.success?
  end
end

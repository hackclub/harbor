class GitRemote
  def self.check_remote_exists(repo_url)
    `git ls-remote #{repo_url}`
    $?.success?
  end
end

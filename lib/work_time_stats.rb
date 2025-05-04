class WorkTimeStats
  def initialize(user_id = nil, project_name)
    @user_id = user_id || "{YOUR_USER_ID}"
    @project_name = project_name || self.class.project_names[0]
  end

  def generate_badge_url
    URI.parse("https://hackatime-badge.hackclub.com/#{@user_id}/#{@project_name}").to_s
  end

  def self.project_names
    all_project_names = []

    scope = User.where.not(github_uid: nil)
    scope = scope.where(id: @user_id) if @user_id.present?

    scope.find_each(batch_size: 100) do |user|
      existing_mappings = user.project_repo_mappings.pluck(:project_name)
      unique_project_names = user.heartbeats.where.not(project: existing_mappings)
                                            .distinct.pluck(:project).compact
      unique_project_names.each { |name| all_project_names << name }
    end
    all_project_names
  end
end

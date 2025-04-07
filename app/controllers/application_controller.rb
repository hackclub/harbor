class ApplicationController < ActionController::Base
  before_action :set_paper_trail_whodunnit
  before_action :initialize_cache_counters

  before_action do
    if current_user && current_user.is_admin?
      Rack::MiniProfiler.authorize_request
    end
  end

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  helper_method :current_user, :user_signed_in?, :active_users_graph_data

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    !!current_user
  end

  def authenticate_user!
    unless user_signed_in?
      redirect_to root_path, alert: "Please sign in first!"
    end
  end

  def initialize_cache_counters
    Thread.current[:cache_hits] = 0
    Thread.current[:cache_misses] = 0
  end

  def increment_cache_hits
    Thread.current[:cache_hits] += 1
  end

  def increment_cache_misses
    Thread.current[:cache_misses] += 1
  end

  def active_users_graph_data
    Cache::ActiveUsersGraphDataJob.perform_now
  end
end

class AdminConstraint
  def self.matches?(request)
    return false unless request.session[:user_id]

    user = User.find_by(id: request.session[:user_id])
    user&.admin?
  end
end

Rails.application.routes.draw do
  get "membership_upgrade_requests/new"
  get "membership_upgrade_requests/create"
  constraints AdminConstraint do
    mount Avo::Engine, at: Avo.configuration.root_path
    mount GoodJob::Engine => "good_job"

    get "/impersonate/:id", to: "sessions#impersonate", as: :impersonate_user

    # Membership routes
    get "membership", to: "memberships#index", as: :membership
    get "my/membership", to: "memberships#show", as: :my_membership, slack_uid: "my"
    get ":slack_uid/membership", to: "memberships#show", as: :user_membership
  end
  get "/stop_impersonating", to: "sessions#stop_impersonating", as: :stop_impersonating

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "static_pages#index"

  resources :static_pages, only: [ :index ] do
    collection do
      get :project_durations
      get :activity_graph
      get :currently_hacking
      get :filterable_dashboard_content
      get :filterable_dashboard
      get "🃏", to: "static_pages#🃏", as: :wildcard
    end
  end

  # Auth routes
  get "/auth/slack", to: "sessions#new", as: :slack_auth
  get "/auth/slack/callback", to: "sessions#create"
  get "/auth/github", to: "sessions#github_new", as: :github_auth
  get "/auth/github/callback", to: "sessions#github_create"
  post "/auth/email", to: "sessions#email", as: :email_auth
  get "/auth/token/:token", to: "sessions#token", as: :auth_token
  delete "signout", to: "sessions#destroy", as: "signout"

  resources :leaderboards, only: [ :index ]

  # Nested under users for admin access
  resources :users, only: [] do
    get "settings", on: :member, to: "users#edit"
  end

  # Namespace for current user actions
  get "my/settings", to: "users#edit", as: :my_settings
  patch "my/settings", to: "users#update"
  post "my/settings/migrate_heartbeats", to: "users#migrate_heartbeats", as: :my_settings_migrate_heartbeats

  get "my/wakatime_setup", to: "users#wakatime_setup"
  get "my/wakatime_setup/step-2", to: "users#wakatime_setup_step_2"
  get "my/wakatime_setup/step-3", to: "users#wakatime_setup_step_3"
  get "my/wakatime_setup/step-4", to: "users#wakatime_setup_step_4"

  post "/sailors_log/slack/commands", to: "slack#create"
  post "/timedump/slack/commands", to: "slack#create"

  # API routes
  namespace :api do
    namespace :v1 do
      get "stats", to: "stats#show"
      get "users/:username/stats", to: "stats#user_stats"

      namespace :my do
        get "heartbeats/most_recent", to: "heartbeats#most_recent"
        get "heartbeats", to: "heartbeats#index"
      end
    end

    namespace :hackatime do
      namespace :v1 do
        get "/", to: "hackatime#index" # many clients seem to link this as the user's dashboard
        get "/users/:id/statusbar/today", to: "hackatime#status_bar_today"
        post "/users/:id/heartbeats", to: "hackatime#push_heartbeats"
      end
    end
  end

  resources :scrapyard_leaderboards, only: [ :index, :show ]

  resources :membership_upgrade_requests, only: [ :new, :create ]
end

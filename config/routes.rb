Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]
  resources :users, only: %i[new create]
  resources :organizations, param: :slug, only: %i[new create show edit update] do
    resources :members, controller: "memberships", only: %i[index show update destroy]
    resource :reports, only: :show, controller: "reports" do
      get :roster
      get :participation
      get :events
    end
    resource :roster_import, only: %i[new create], controller: "roster_imports"
    resources :invitations, only: %i[index new create destroy]
    resources :join_links, controller: "organization_join_links", only: %i[index new create destroy]
    resources :announcements
    resources :events do
      resource :rsvp, only: %i[create update]
      resource :attendance, only: :show, controller: "event_attendance"
      patch "attendance/:membership_id", to: "event_attendance#update", as: :attendance_record
      resource :check_in_settings, only: :update, controller: "event_check_in_settings"
      resource :check_in, only: :create, controller: "event_check_ins"
    end
  end
  resources :invitation_acceptances, path: "invitations", param: :token, only: %i[show update]
  get "join/:token", to: "organization_join_acceptances#show", as: :organization_join
  patch "join/:token", to: "organization_join_acceptances#update"

  root "home#show"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end

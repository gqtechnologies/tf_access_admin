Rails.application.routes.draw do

  # Redirect to localhost from 127.0.0.1 to use same IP address with Vite server
  constraints(host: "127.0.0.1") do
    get "(*path)", to: redirect { |params, req| "#{req.protocol}localhost:#{req.port}/#{params[:path]}" }
  end

  get "home/index"
  #Remove this route
  devise_for :users, controllers: {
    sessions: "users/sessions"
  }
  
  get "admin/home/index"
  namespace :admin do
    resources :users, only: [:index, :new, :create, :edit, :update, :destroy]
    resources :profile, only: [:edit, :update]
    match "*path", to: "errors#not_found", via: :all
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  match "*path", to: "errors#not_found", via: :all
  # Defines the root path route ("/")
  root "admin/home#index"
end

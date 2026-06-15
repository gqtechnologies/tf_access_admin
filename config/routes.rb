require "sidekiq/web"

Rails.application.routes.draw do
  # Redirect to localhost from 127.0.0.1 to use same IP address with Vite server
  constraints(host: "127.0.0.1") do
    get "(*path)", to: redirect { |params, req| "#{req.protocol}localhost:#{req.port}/#{params[:path]}" }
  end

  authenticate :user, lambda { |u| u.super_admin? } do
    mount Sidekiq::Web => "/sidekiq"
    mount Flipper::UI.app(Flipper) => "/flipper"
  end
  # Público / sin tenant (dominio base o sin subdominio de organización)
  get "home", to: "home#index", as: :home

  # Solo rutas Devise necesarias: login (Inertia), recuperación de contraseña, confirmación por email.
  # No exponer registrations (sign up), unlocks ni otros módulos hasta implementarlos.
  devise_for :users,
             only: %i[sessions passwords confirmations],
             controllers: {
               sessions: "users/sessions",
               passwords: "users/passwords",
               confirmations: "users/confirmations"
             }

  namespace :api do
    namespace :v1 do
      namespace :auth do
        post :login, to: "sessions#create"
        delete :logout, to: "sessions#destroy"
      end

      # namespace :public do
      #   resources :organizations, only: [:index]
      # end

      namespace :private do
      end
    end
  end

  get "admin/home/index"
  namespace :admin do
    resources :users, only: [:index, :new, :create, :edit, :update, :destroy]
    resources :people, only: [:index, :new, :create, :edit, :update, :destroy]
    resources :profile, only: [:edit, :update]
    resources :organizations, only: [:index, :show, :edit, :update, :new, :create, :destroy]
    resources :residential_properties, only: [:index, :new, :create, :edit, :update, :destroy] do
      resource :structure, only: [:show], module: :residential_properties
      resources :units, only: [:show], module: :residential_properties do
        resources :ownerships, only: [:create, :update, :destroy], controller: "unit_ownerships"
        resources :occupancies, only: [:create, :update, :destroy], controller: "unit_occupancies"
      end
      resources :property_sections, only: [:create, :update, :destroy], module: :residential_properties
      resources :bulk_imports, only: %i[create update], module: :residential_properties do
        member do
          post :validate
          post :confirm
          get :rows
          get :status
          get :report
        end
      end
    end
    resources :property_sections, only: [:index, :edit, :update, :destroy]
    match "*path", to: "errors#not_found", via: :all
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  match "*path", to: "errors#not_found", via: :all,
  constraints: lambda { |req|
    !req.path.start_with?("/rails/active_storage")
  }
  # Defines the root path route ("/")
  root "admin/home#index"
end

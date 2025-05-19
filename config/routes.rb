Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  devise_scope :user do
    delete '/users/oauth', to: 'users/registrations#unlink_oauth', as: :unlink_oauth
  end

  resource :two_factor_settings, except: [:show, :update]

  resources :users, only: [:show, :edit, :update] do
    member do
      get "two_factor_authentication"
    end
  end

  resources :messages, only: [:index, :create, :destroy]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  root 'messages#index'
end

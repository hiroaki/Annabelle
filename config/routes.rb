Rails.application.routes.draw do
  # ルートパスアクセス時の自動ロケール決定・リダイレクト
  get '/', to: 'locale_redirect#root'

  # OmniAuthコールバックは動的セグメントをサポートしないため、スコープ外に配置
  # OAuth認証は明示的ロケール必須化の例外として扱う
  devise_for :users, only: :omniauth_callbacks, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  # OmniAuth失敗パスもロケールスコープ外に配置（OmniAuthの標準フローに合わせる）
  devise_scope :user do
    get '/users/auth/failure', to: 'users/omniauth_callbacks#failure', as: :user_omniauth_failure
  end

  # ロケールをURLに必須化（オプショナルから必須へ変更）
  scope ":locale", locale: /en|ja/ do
    devise_for :users, skip: :omniauth_callbacks, controllers: {
      registrations: 'users/registrations',
      sessions: 'users/sessions'
    }

    devise_scope :user do
      delete '/users/oauth', to: 'users/registrations#unlink_oauth', as: :unlink_oauth
    end

    resource :two_factor_settings, except: [:show, :update]

    # resources :users, only: [:show, :edit, :update] do
    #   member do
    #     get "two_factor_authentication"
    #   end
    # end
    resources :users, only: []
    get '/dashboard', to: 'users#show', as: :dashboard
    get '/profile/edit', to: 'users#edit', as: :edit_profile
    patch '/profile', to: 'users#update', as: :update_profile
    get '/profile/two_factor_authentication', to: 'users#two_factor_authentication', as: :two_factor_authentication

    resources :messages, only: [:index, :create, :destroy]

    # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

    # Defines the localized root path route ("/ja", "/en" etc)
    root 'messages#index'
  end

  # ロケール切り替え用の独立したルート（ロケールスコープの外）
  get 'locale/:locale', to: 'locale#update', as: :locale

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end

Rails.application.routes.draw do
  # OmniAuthコールバックは動的セグメントをサポートしないため、スコープ外に配置
  devise_for :users, only: :omniauth_callbacks, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  # ロケールをURLに含めるためのスコープ
  scope "(:locale)", locale: /en|ja/ do
    devise_for :users, skip: :omniauth_callbacks, controllers: {
      registrations: 'users/registrations',
      sessions: 'users/sessions'
    }

    devise_scope :user do
      delete '/users/oauth', to: 'users/registrations#unlink_oauth', as: :unlink_oauth
      get '/users/auth/failure', to: 'users/omniauth_callbacks#failure', as: :user_omniauth_failure
    end

    resource :two_factor_settings, except: [:show, :update]

    resources :users, only: [:show, :edit, :update] do
      member do
        get "two_factor_authentication"
      end
    end

    resources :messages, only: [:index, :create, :destroy]

    # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

    # Defines the root path route ("/")
    # root "posts#index"
    root 'messages#index'
  end

  # Railsガイドの推奨: ロケールのみのURL（/ja, /en など）を明示的にサポート
  # 他のルーティングを「食べてしまう」ことのないよう、最後に配置
  get "/:locale" => "messages#index", constraints: { locale: /en|ja/ }

  # ロケール切り替え用の独立したルート（ロケールスコープの外）
  get 'locale/:locale', to: 'locale#update', as: :locale

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end

# Userリソースのルーティング整理・id排除 改修計画

## 目的
- current_user専用のユーザー情報ページのURLからuser.idを排除し、将来的な脆弱性リスクを低減する

## 前提

現在 routes.rb だけ修正済みで、この修正の結果が前提になります。つまり修正前のルート設定に関係するすべての箇所を確認し、必要な修正を行って行ってください。

修正前：

  ```
  resources :users, only: [:show, :edit, :update] do
    member do
      get "two_factor_authentication"
    end
  end
  ```

修正後：

  ```
  resources :users, only: []
  get '/dashboard', to: 'users#show', as: :dashboard
  get '/profile/edit', to: 'users#edit', as: :edit_profile
  patch '/profile', to: 'users#update', as: :update_profile
  get '/profile/two_factor_authentication', to: 'users#two_factor_authentication', as: :two_factor_authentication
  ```

## ステップ

### 1. ルーティングの整理（現状の確認）
- `resources :users, only: []` のまま、id付きルートを生成しない
- `/dashboard`, `/profile/edit`, `/profile`, `/profile/two_factor_authentication` のみ許可

### 2. コントローラ修正
- `UsersController` の `show`, `edit`, `update`, `two_factor_authentication` で `params[:id]` を使っていないか確認し、current_userのみを扱うように統一
- 必要に応じて `before_action` なども見直す

### 3. ビュー・リンク修正
- id付きのユーザーURL（例: `user_path(user)`）を使っていないか全体検索し、`dashboard_path` などに置き換える

### 4. テスト修正
- ルートやコントローラのテストでid付きURLを使っていないか確認し、current_user専用のパスに修正

### 5. ドキュメント更新（必要に応じて）
- READMEや設計書にルート設計の方針を明記

## ルーティング改修に伴い編集が必要となる主なファイル一覧（調査結果）

- `config/routes.rb`  
  ルーティング定義の最終確認・整理

- `app/controllers/users_controller.rb`  
  - `show`, `edit`, `update`, `two_factor_authentication` 各アクションで `params[:id]` を使っていないか確認・修正
  - `redirect_to edit_user_path(@user)` などid付きパスの利用箇所の修正

- ビュー・ヘルパー
  - `app/views/layouts/_configuration_menu.html.erb`  
    `edit_user_path(current_user)` などid付きパスの利用箇所
  - その他、`user_path(user)`, `edit_user_path(user)` などを使っている全てのビュー・ヘルパー

- テスト
  - `spec/requests/users_controller_spec.rb`  
    id付きパスを使ったリクエストテスト多数
  - `spec/system/user_profile_spec.rb`  
    `visit edit_user_path(user)` など
  - `spec/helpers/locale_helper_spec.rb`  
    id付きパスのstubやテスト
  - `spec/requests/two_factor_settings_spec.rb`  
    `two_factor_authentication_user_path(user)` など
  - その他、`user_path`, `edit_user_path`, `two_factor_authentication_user_path` などを使っているテスト全般

---

この計画ファイルをもとに、各ステップを小さなPRやAIセッション単位で進めてください。

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OmniauthCallbacks', type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:provider) { :github }
  let(:uid) { '12345' }
  let(:auth_hash) do
    OmniAuth::AuthHash.new(
      provider: provider,
      uid: uid,
      info: { email: 'test@example.com' }
    )
  end

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[provider] = auth_hash
  end

  after do
    OmniAuth.config.mock_auth[provider] = nil
    OmniAuth.config.test_mode = false
  end

  describe 'GET /users/auth/github/callback' do
    context 'when user is signed in and not yet linked' do
      before { sign_in user }

      it 'links the provider and redirects with success message' do
        expect {
          get user_github_omniauth_callback_path
        }.to change { user.authorizations.count }.by(1)
        expect(response).to redirect_to(edit_user_registration_path)
        follow_redirect!
        # flashメッセージはTurbo/redirect後のHTMLには含まれない場合があるため、flash[:notice]で検証
        expect(flash[:notice]).to eq(I18n.t('devise.omniauth_callbacks.provider.success', provider: 'GitHub'))
      end
    end

    context 'when user is signed in and already linked with different uid' do
      before do
        user.authorizations.create!(provider: provider, uid: 'other_uid')
        sign_in user
      end

      it 'does not link and redirects with already_linked message' do
        get user_github_omniauth_callback_path
        expect(response).to redirect_to(edit_user_registration_path)
        follow_redirect!
        expect(flash[:alert]).to eq(I18n.t('devise.omniauth_callbacks.provider.already_linked', provider: 'GitHub'))
      end
    end

    context 'when user is not signed in and user can be found/created' do
      it 'signs in and redirects to edit registration page' do
        allow(User).to receive(:from_omniauth).and_return(user)
        get user_github_omniauth_callback_path
        expect(response).to redirect_to(edit_user_registration_path)
      end
    end

    context 'when user is not signed in and user cannot be persisted' do
      it 'redirects to sign up with failure message' do
        allow(User).to receive(:from_omniauth).and_return(User.new)
        get user_github_omniauth_callback_path
        expect(response).to redirect_to(new_user_registration_path)
        follow_redirect!
        expect(flash[:alert]).to eq(I18n.t('devise.omniauth_callbacks.failure', kind: 'GitHub'))
      end
    end
  end

  describe 'GET /users/auth/failure' do
    it 'redirects to sign in with failure message' do
      # OmniAuth失敗パスはロケールスコープ外なのでロケールなしでアクセス
      get '/users/auth/failure'
      expect(response).to redirect_to(new_user_session_path(locale: 'en'))
      follow_redirect!
      expect(flash[:alert]).to eq(I18n.t('devise.omniauth_callbacks.failure', kind: I18n.t('devise.omniauth_callbacks.unknown_provider')))
    end
  end

  # ステップ5: OAuth改善のテストケース
  describe 'OAuth locale handling improvements' do
    context 'with session-based locale fallback' do
      it 'uses session locale when omniauth params are missing' do
        # OAuth認証開始時のシミュレーション：セッションにロケール保存
        # （実際はDeviseのOAuth開始リンクから行われる）

        # 既存ユーザーであることを明示的に設定
        allow(user).to receive(:saved_change_to_id?).and_return(false)
        allow(User).to receive(:from_omniauth).and_return(user)

        # セッションベースの設定のテスト
        # OAuthコールバックでセッションからロケールを復元することをモック
        allow_any_instance_of(Users::OmniauthCallbacksController).to receive(:restore_oauth_locale_from_session).and_return('ja')

        get user_github_omniauth_callback_path

        # 既存ユーザーはrootパスにリダイレクトされる
        expect(response).to redirect_to(root_path(locale: 'ja'))
      end
    end

    context 'with Accept-Language header fallback' do
      it 'uses browser language when other sources are unavailable' do
        # 既存ユーザーであることを明示的に設定
        allow(user).to receive(:saved_change_to_id?).and_return(false)
        allow(User).to receive(:from_omniauth).and_return(user)

        # 日本語のAccept-Languageヘッダーを設定
        get user_github_omniauth_callback_path, headers: { 'HTTP_ACCEPT_LANGUAGE' => 'ja,en;q=0.8' }

        # 既存ユーザーはrootパスにリダイレクトされる
        expect(response).to redirect_to(root_path(locale: 'ja'))
      end
    end

    context 'with user preference fallback' do
      let(:ja_user) { create(:user, :confirmed, preferred_language: 'ja') }

      context 'when user is signed in (account linking)' do
        before { sign_in ja_user }

        it 'uses user preference for account linking page' do
          get user_github_omniauth_callback_path

          # サインイン済みユーザーはアカウント連携のため編集ページにリダイレクト
          expect(response).to redirect_to(edit_user_registration_path(locale: 'ja'))
        end
      end

      context 'when user is NOT signed in (login)' do
        it 'uses user preference after OAuth login' do
          # OAuth認証で取得するユーザーの言語設定を日本語に設定
          allow(ja_user).to receive(:saved_change_to_id?).and_return(false)
          allow(ja_user).to receive(:preferred_language).and_return('ja')
          allow(User).to receive(:from_omniauth).and_return(ja_user)

          get user_github_omniauth_callback_path

          # OAuth経由ログイン後、ユーザー設定に基づいてrootパスにリダイレクト
          expect(response).to redirect_to(root_path(locale: 'ja'))
        end
      end
    end

    context 'with new user registration' do
      let(:new_user) { build(:user, :confirmed) }

      it 'redirects new user to edit registration page with proper locale' do
        # 新規ユーザーとしてモック
        allow(new_user).to receive(:persisted?).and_return(true)
        allow(new_user).to receive(:saved_change_to_id?).and_return(true)
        allow(User).to receive(:from_omniauth).and_return(new_user)

        get user_github_omniauth_callback_path, headers: { 'HTTP_ACCEPT_LANGUAGE' => 'ja,en;q=0.8' }

        # 新規ユーザーは編集ページにリダイレクトされる
        expect(response).to redirect_to(edit_user_registration_path(locale: 'ja'))
      end
    end
  end
end

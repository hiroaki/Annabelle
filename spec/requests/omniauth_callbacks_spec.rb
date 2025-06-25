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
        expect(flash[:notice]).to eq(I18n.t('devise.omniauth_callbacks.provider.linked', provider: 'GitHub'))
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

    describe '既存ユーザーがOmniAuthでサインインした場合' do
      it 'root_pathにリダイレクトされる' do
        existing_user = create(:user, :confirmed)
        allow(User).to receive(:from_omniauth).and_return(existing_user)
        allow(existing_user).to receive(:persisted?).and_return(true)
        allow(existing_user).to receive(:saved_change_to_id?).and_return(false)
        get user_github_omniauth_callback_path
        expect(response).to redirect_to(root_path(locale: 'en'))
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

    it 'handles auth_failure action correctly' do
      # failureアクションの正常な動作を確認
      get '/users/auth/failure'
      expect(response).to redirect_to(new_user_session_path(locale: 'en'))
    end

    it 'extracts provider name from error_strategy' do
      strategy = double('strategy', name: 'github')
      get '/users/auth/failure', env: { "omniauth.error.strategy" => strategy }
      expect(flash[:alert]).to include('GitHub')
    end

    it 'falls back to failure_fallback when interpolation is missing' do
      allow(I18n).to receive(:t).and_call_original
      error = I18n::MissingInterpolationArgument.new(:kind, {}, "translation string")
      allow(I18n).to receive(:t).with("devise.omniauth_callbacks.failure", kind: anything).and_raise(error)
      allow(I18n).to receive(:t).with("devise.omniauth_callbacks.failure_fallback").and_return("fallback message")
      get '/users/auth/failure'
      follow_redirect!
      expect(flash[:alert]).to eq("fallback message")
    end
  end
end

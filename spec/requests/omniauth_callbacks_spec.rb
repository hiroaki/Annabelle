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

      it 'creates a new authorization record for the user' do
        expect {
          get user_github_omniauth_callback_path
        }.to change { user.authorizations.count }.by(1)
      end

      it 'redirects to the edit registration page after linking' do
        get user_github_omniauth_callback_path
        expect(response).to redirect_to(edit_user_registration_path)
      end
    end

    context 'when user is signed in and already linked with same uid (self-link)' do
      before do
        user.authorizations.create!(provider: provider, uid: uid)
        sign_in user
      end

      it 'does not create a new authorization and shows already_linked alert (self-link)' do
        expect {
          get user_github_omniauth_callback_path
        }.not_to change { user.authorizations.count }
        expect(response).to redirect_to(edit_user_registration_path)
        follow_redirect!
        expect(flash[:alert]).to eq(I18n.t('devise.omniauth_callbacks.provider.already_linked', provider: 'GitHub'))
      end
    end

    context 'when user is signed in and another user already linked with same provider/uid' do
      let!(:other_user) { create(:user, :confirmed) }
      before do
        other_user.authorizations.create!(provider: provider, uid: uid)
        sign_in user
      end

      it 'does not create a new authorization and shows already_linked alert (other user)' do
        expect {
          get user_github_omniauth_callback_path
        }.not_to change { user.authorizations.count }
        expect(response).to redirect_to(edit_user_registration_path)
        follow_redirect!
        expect(flash[:alert]).to eq(I18n.t('devise.omniauth_callbacks.provider.already_linked', provider: 'GitHub'))
      end
    end

    context 'when user is signed in and link_with triggers a validation error (race condition)' do
      before do
        sign_in user
        # Simulate race: provider_uid_exists? returns false, but link_with fails due to validation
        allow(Authorization).to receive(:provider_uid_exists?).and_return(false)
        allow_any_instance_of(User).to receive(:link_with).and_wrap_original do |m, *args|
          auth = m.receiver.authorizations.build(provider: args[0], uid: args[1])
          auth.errors.add(:uid, 'has already been taken')
          auth
        end
      end

      it 'does not create a new authorization and shows already_linked alert if link_with fails validation' do
        expect {
          get user_github_omniauth_callback_path
        }.not_to change { user.authorizations.count }
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

    describe 'when an existing user signs in via OmniAuth' do
      it 'redirects to root_path' do
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
    it 'redirects to sign in with failure message (unknown provider)' do
      get '/users/auth/failure'
      expect(response).to redirect_to(new_user_session_path(locale: 'en'))
      follow_redirect!
      expect(flash[:alert]).to eq(I18n.t('devise.omniauth_callbacks.failure', kind: I18n.t('devise.omniauth_callbacks.unknown_provider')))
    end

    it 'redirects to sign in on auth_failure action' do
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

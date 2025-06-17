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
  end

  # OAuth改善のテストケース
  describe 'OAuth locale handling improvements' do
    context 'with session-based locale fallback' do
      it 'uses session locale when omniauth params are missing' do
        # OAuth認証開始時のシミュレーション：セッションにロケール保存
        # （実際はDeviseのOAuth開始リンクから行われる）

        # 既存ユーザーであることを明示的に設定
        allow(user).to receive(:saved_change_to_id?).and_return(false)
        allow(User).to receive(:from_omniauth).and_return(user)

        # セッションベースの設定のテスト
        # OAuthLocaleServiceのrestore_oauth_locale_from_sessionメソッドをモック
        allow_any_instance_of(OAuthLocaleService).to receive(:restore_oauth_locale_from_session).and_return('ja')

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

  # Note: 以下のテストはrequest specの範囲を超えて、privateメソッドの単体テストを行っています。
  # 本来はspec/models/やspec/lib/に分離するか、controller specで書くべきですが、
  # 小さな範囲のため、関連の強いこのファイルに含めています。

  describe 'Private methods unit tests (for coverage)' do
    let(:controller) { Users::OmniauthCallbacksController.new }

    describe '#extract_provider_name_for_error' do
      context 'when error_strategy with name exists' do
        it 'returns camalized name of the strategy' do
          error_strategy = double('OmniAuth::Strategies::Base')
          allow(error_strategy).to receive(:name).and_return(:github)
          request = double('request')
          allow(request).to receive(:env).and_return({"omniauth.error.strategy" => error_strategy})
          allow(controller).to receive(:request).and_return(request)

          result = controller.send(:extract_provider_name_for_error)
          expect(result).to eq('GitHub')
        end
      end

      context 'when error_strategy does not exist' do
        it 'returns unknown provider message' do
          request = double('request')
          allow(request).to receive(:env).and_return({})
          allow(controller).to receive(:request).and_return(request)

          result = controller.send(:extract_provider_name_for_error)
          expect(result).to eq(I18n.t('devise.omniauth_callbacks.unknown_provider'))
        end
      end
    end

    describe '#generate_failure_message' do
      context 'when translation key has all required interpolations' do
        it 'returns the translated message with provider' do
          allow(I18n).to receive(:t).with("devise.omniauth_callbacks.failure", kind: "GitHub").and_return("Could not authenticate you from GitHub")

          result = controller.send(:generate_failure_message, "GitHub")
          expect(result).to eq("Could not authenticate you from GitHub")
          expect(I18n).to have_received(:t).with("devise.omniauth_callbacks.failure", kind: "GitHub")
        end
      end

      context 'when MissingInterpolationArgument exception occurs' do
        it 'returns the fallback message' do
          allow(I18n).to receive(:t).with("devise.omniauth_callbacks.failure", kind: "GitHub").and_raise(I18n::MissingInterpolationArgument.new("key", "string", "values"))
          allow(I18n).to receive(:t).with("devise.omniauth_callbacks.failure_fallback").and_return("Authentication failed")

          result = controller.send(:generate_failure_message, "GitHub")
          expect(result).to eq("Authentication failed")
          expect(I18n).to have_received(:t).with("devise.omniauth_callbacks.failure_fallback")
        end
      end
    end

    describe 'Defensive code branch coverage' do
      it 'determine_redirect_path handles unknown action' do
        allow(controller).to receive(:oauth_locale_for).and_return('en')
        allow(controller).to receive(:root_path).with(locale: 'en').and_return('/en')

        result = controller.send(:determine_redirect_path, :unknown_action, nil)
        expect(result).to eq('/en')
      end

      it 'localized_path handles unknown path_name' do
        allow(controller).to receive(:oauth_locale_for).and_return('en')
        allow(controller).to receive(:root_path).with(locale: 'en').and_return('/en')

        result = controller.send(:localized_path, :unknown_path, nil)
        expect(result).to eq('/en')
      end
    end
  end
end

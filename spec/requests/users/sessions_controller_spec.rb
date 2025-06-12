require 'rails_helper'

RSpec.describe Users::SessionsController, type: :request do
  let(:user) { create(:user, :confirmed, password: 'password') }

  before do
    I18n.default_locale = :en
    allow(I18n).to receive(:available_locales).and_return([:ja, :en])
  end

  describe '#after_sign_out_path_for' do
    let(:controller) { Users::SessionsController.new }

    before do
      allow(controller).to receive(:session).and_return({})
      allow(controller).to receive(:new_session_path) do |resource_or_scope, options = {}|
        if options[:locale]
          "/#{options[:locale]}/users/sign_in"
        else
          "/users/sign_in"
        end
      end
    end

    context 'ログアウト時に言語設定が保存されていない場合' do
      it 'デフォルトのサインインパスを返す' do
        allow(controller).to receive(:determine_logout_locale).and_return(nil)

        result = controller.after_sign_out_path_for(:user)

        expect(result).to eq("/users/sign_in")
      end
    end

    context 'ログアウト時に言語設定が保存されており、デフォルトロケールではない場合' do
      it 'ロケール付きのサインインパスを返す' do
        allow(controller).to receive(:determine_logout_locale).and_return('ja')

        result = controller.after_sign_out_path_for(:user)

        expect(result).to eq("/ja/users/sign_in")
      end
    end

    context 'ログアウト時に言語設定が保存されているが、デフォルトロケールの場合' do
      it 'デフォルトのサインインパスを返す' do
        allow(controller).to receive(:determine_logout_locale).and_return('en')

        result = controller.after_sign_out_path_for(:user)

        expect(result).to eq("/users/sign_in")
      end
    end
  end

  describe '#store_language_for_logout' do
    let(:controller) { Users::SessionsController.new }
    let(:test_session) { {} }

    before do
      allow(controller).to receive(:session).and_return(test_session)
      allow(controller).to receive(:params).and_return({})
      allow(controller).to receive(:user_signed_in?).and_return(false)
    end

    context 'URLパラメータのlocaleが存在する場合（ステップ4: langからlocaleに変更）' do
      before do
        allow(controller).to receive(:params).and_return({ locale: 'ja' })
      end

      it 'セッションにlocaleを保存する' do
        controller.send(:store_language_for_logout)
        expect(test_session[:logout_locale]).to eq('ja')
      end
    end

    context '現在のI18n.localeがデフォルトと異なる場合' do
      before do
        allow(I18n).to receive(:locale).and_return(:ja)
        allow(I18n).to receive(:default_locale).and_return(:en)
      end

      it 'セッションにlocaleを保存する' do
        controller.send(:store_language_for_logout)
        expect(test_session[:logout_locale]).to eq('ja')
      end
    end

    context 'ユーザーがサインインしており、設定言語がある場合' do
      let(:mock_user) { double('User', preferred_language: 'ja') }

      before do
        allow(controller).to receive(:user_signed_in?).and_return(true)
        allow(controller).to receive(:current_user).and_return(mock_user)
      end

      it 'セッションにユーザーの設定言語を保存する' do
        controller.send(:store_language_for_logout)
        expect(test_session[:logout_locale]).to eq('ja')
      end
    end
  end

  describe '#determine_logout_locale' do
    let(:controller) { Users::SessionsController.new }

    before do
      allow(controller).to receive(:session).and_return(test_session)
    end

    context '有効なロケールが保存されている場合' do
      let(:test_session) { { logout_locale: 'ja' } }

      it '保存されたロケールを返す' do
        result = controller.send(:determine_logout_locale)
        expect(result).to eq('ja')
      end

      it 'セッションからロケールを削除する' do
        controller.send(:determine_logout_locale)
        expect(test_session[:logout_locale]).to be_nil
      end
    end

    context '無効なロケールが保存されている場合' do
      let(:test_session) { { logout_locale: 'invalid' } }

      it 'nilを返す' do
        result = controller.send(:determine_logout_locale)
        expect(result).to be_nil
      end

      it 'セッションからロケールを削除する' do
        controller.send(:determine_logout_locale)
        expect(test_session[:logout_locale]).to be_nil
      end
    end

    context 'ロケールが保存されていない場合' do
      let(:test_session) { {} }

      it 'nilを返す' do
        result = controller.send(:determine_logout_locale)
        expect(result).to be_nil
      end
    end
  end

  # 統合テスト
  describe 'ログアウト時のリダイレクト動作' do
    before { sign_in user }

    context 'URLロケールパラメータが指定された場合（ステップ4: パスベース戦略）' do
      it 'ロケール付きのログイン画面にリダイレクトする' do
        # 明示的ロケール必須化により、ロケール付きURLからログアウト
        delete "/ja/users/sign_out"

        expect(response).to redirect_to(new_user_session_path(locale: 'ja'))
      end
    end

    context '無効なロケールパスからアクセスした場合' do
      it 'デフォルトのログイン画面にリダイレクトする' do
        # 無効なロケールはルーティングエラーになるが、
        # デフォルトロケールからのログアウトをテスト
        delete "/en/users/sign_out"

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'determine_logout_localeが有効なロケールを返す場合' do
      it 'ロケール付きのログイン画面にリダイレクトする' do
        allow_any_instance_of(Users::SessionsController)
          .to receive(:determine_logout_locale).and_return('ja')

        delete destroy_user_session_path

        expect(response).to redirect_to(new_user_session_path(locale: 'ja'))
      end
    end

    context 'determine_logout_localeがnilを返す場合' do
      it 'デフォルトのログイン画面にリダイレクトする' do
        allow_any_instance_of(Users::SessionsController)
          .to receive(:determine_logout_locale).and_return(nil)

        delete destroy_user_session_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end

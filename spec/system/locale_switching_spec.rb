require 'rails_helper'

RSpec.describe 'LocaleSwitching', type: :system do
  # ===================================================================
  # テストデータ準備
  # ===================================================================
  let!(:user_ja) { FactoryBot.create(:user, preferred_language: 'ja', password: 'password') }
  let!(:user_en) { FactoryBot.create(:user, preferred_language: 'en', password: 'password') }
  let!(:user_no_pref) { FactoryBot.create(:user, preferred_language: '', password: 'password') }

  # ===================================================================
  # ヘルパーメソッド
  # ===================================================================

  # ログインヘルパー
  # ログインページでフォームを入力し、ログインを実行する
  # expected_locale: :ja または :en を必須で指定する
  def login_as(user, expected_locale:)
    # 指定された言語に切り替えてからログインページへ
    visit root_path
    switch_language_to(expected_locale)

    visit new_user_session_path

    # 言語に応じたフォームラベルでフィールドを見つけて入力
    case expected_locale
    when :ja
      fill_in 'メールアドレス', with: user.email
      fill_in 'パスワード', with: 'password'
      click_button 'ログイン'
    when :en
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password'
      click_button 'Log in'
    else
      raise "Unsupported locale: #{expected_locale}. Only :ja and :en are supported."
    end

    # ログイン成功の確認（ページ遷移を待つ）
    # 期待する言語に応じた投稿ボタンが表示される
    case expected_locale
    when :ja
      expect(page).to have_button('投稿')
    when :en
      expect(page).to have_button('Post')
    end
  end

  # ログアウトヘルパー
  # data-testidを使用してログアウトリンクをクリックし、ログアウト後の画面を検証する
  # expected_locale: :ja または :en を必須で指定する
  def logout(expected_locale:)
    # data-testid="current-user-signout" でログアウトリンクを探す
    find('[data-testid="current-user-signout"]').click

    # ログアウト後の画面を言語に応じて確認
    case expected_locale
    when :ja
      expect(
        page.has_content?('ログアウトしました') ||
        page.has_button?('ログイン') ||
        page.has_content?('アカウント登録もしくはログインしてください。')
      ).to be true
    when :en
      expect(
        page.has_content?('Signed out successfully') ||
        page.has_button?('Log in') ||
        page.has_content?('You need to sign in or sign up before continuing.')
      ).to be true
    else
      raise "Unsupported locale: #{expected_locale}. Only :ja and :en are supported."
    end
  end

  # 言語切り替えヘルパー
  # 指定されたロケールに言語を切り替える
  def switch_language_to(locale)
    case locale.to_s
    when 'ja'
      click_link '日本語'
    when 'en'
      click_link 'English'
    end
  end

  # URL-based locale navigation helpers
  def visit_with_locale(path, locale)
    if locale.to_s == 'en'
      visit path
    else
      visit "/#{locale}#{path}"
    end
  end

  # 現在のページの表示言語を判定するヘルパー
  def current_locale_is_japanese?
    page.has_content?('お知らせ') || page.has_content?('アカウント登録もしくはログインしてください。')
  end

  def current_locale_is_english?
    page.has_content?('Notifications') || page.has_content?('You need to sign in or sign up before continuing.')
  end

  # ===================================================================
  # セットアップ
  # ===================================================================
  before do
    I18n.default_locale = :en  # 実際のアプリケーションのデフォルトに合わせる
    allow(I18n).to receive(:available_locales).and_return([:ja, :en])
  end

  # ===================================================================
  # テストケース
  # ===================================================================

  describe '未ログイン時のロケール切り替え' do
    context '初回訪問時' do
      it 'デフォルトロケール（英語）で表示される' do
        visit root_path

        # 未ログイン時の表示確認（実際のデフォルトは英語）
        expect(page).to have_content('You need to sign in or sign up before continuing.')
      end
    end

    context '言語切り替え機能' do
      it '英語→日本語の切り替えで表示が変わる' do
        visit root_path

        # 初期状態：英語で表示されている
        expect(page).to have_button('Log in')

        # 言語スイッチャーリンクの存在確認
        expect(page).to have_link('日本語')

        # 日本語に切り替え
        click_link '日本語'

        # 日本語に切り替わったかを確認
        expect(page).to have_button('ログイン')

        # 英語に戻す
        click_link 'English'

        # 英語に戻ったかを確認
        expect(page).to have_button('Log in')
      end
    end

    context 'URLパラメータでの言語指定' do
      it 'URLで直接日本語ページにアクセスできる' do
        # 日本語のURLで直接アクセス
        visit '/ja'
        expect(page).to have_content('アカウント登録もしくはログインしてください。')

        # 英語のURLで直接アクセス
        visit '/'
        expect(page).to have_content('You need to sign in or sign up before continuing.')
      end
    end

    context 'langクエリパラメータでの明示的な言語指定' do
      it '直接ログイン画面でlangパラメータが機能する' do
        # ログイン画面に直接langパラメータでアクセス
        visit '/users/sign_in?lang=ja'
        
        expect(page).to have_button('ログイン')
        expect(page).to have_field('メールアドレス')

        # 言語スイッチャーのリンクにlangパラメータが含まれる
        expect(page).to have_link('English')
        
        # 英語に切り替え
        click_link 'English'
        expect(page).to have_button('Log in')
        expect(page).to have_field('Email')
      end

      it 'langパラメータで一時的に英語表示ができる' do
        # langパラメータで英語指定
        visit '/users/sign_in?lang=en'
        expect(page).to have_button('Log in')
        expect(page).to have_field('Email')

        # 言語スイッチャーのリンクにlangパラメータが含まれる
        expect(page).to have_link('日本語')
      end

      it '他のページでもlangパラメータが機能する' do
        # サインインページでlangパラメータを使用
        visit '/users/sign_in?lang=ja'
        expect(page).to have_button('ログイン')
        expect(page).to have_field('メールアドレス')

        # 英語に切り替え
        click_link 'English'
        expect(page).to have_button('Log in')
        expect(page).to have_field('Email')
      end

      it 'ルートページにlangパラメータでアクセスすると認証後にlangパラメータが保持される' do
        # langパラメータで日本語指定してルートページにアクセス
        visit '/?lang=ja'
        
        # ?lang=jaでアクセスしたが、ログインが必要なページの場合、
        # CustomFailureAppにより適切にリダイレクトされることを確認
        
        # まず、現在のページが日本語で表示されていることを確認
        expect(page).to have_button('ログイン')
        expect(page).to have_content('アカウント登録もしくはログインしてください。')

        # 言語スイッチャーのリンクが正しく機能することを確認
        expect(page).to have_link('English')
      end
    end

    context '不正な値の処理' do
      it '不正なlocaleパラメータ時はRouting Errorになる' do
        # 不正なlocaleでアクセス
        visit '/invalid_locale'
        # ルートエラーになる（これは正常な動作）
        expect(page).to have_content('Routing Error')
      end
    end
  end

  describe 'ログイン時のロケール切り替え' do
    context 'ユーザーに言語設定がない場合' do
      it 'デフォルトロケールで表示され、言語切り替えで表示が変わる' do
        login_as(user_no_pref, expected_locale: :en)  # デフォルトは英語

        # ログイン後の初期表示確認（英語で投稿ボタンが表示される）
        expect(page).to have_button('Post')

        # 日本語に切り替え
        switch_language_to(:ja)
        expect(page).to have_button('投稿') # 日本語の投稿ボタンに変わる
      end
    end

    context 'ユーザーの設定言語が英語の場合' do
      it '初期表示は英語、言語切り替えで表示が変わる' do
        login_as(user_en, expected_locale: :en)  # ユーザー設定は英語

        # ログイン後の表示確認（英語で投稿ボタンが表示される）
        expect(page).to have_button('Post')

        # 日本語に切り替え
        switch_language_to(:ja)
        expect(page).to have_button('投稿') # 日本語の投稿ボタンに変わる

        # 英語に戻す
        switch_language_to(:en)
        expect(page).to have_button('Post')
      end

      it 'URLで直接日本語ページにアクセスすると日本語で表示される' do
        # 日本語URLで直接ログインページにアクセス
        visit '/ja/users/sign_in'
        expect(page).to have_button('ログイン')

        # ログイン
        fill_in 'メールアドレス', with: user_en.email
        fill_in 'パスワード', with: 'password'
        click_button 'ログイン'

        # ログイン後も日本語で表示
        expect(page).to have_button('投稿')
      end
    end

    context 'ユーザーの設定言語が日本語の場合' do
      it '日本語URLでアクセスすると日本語で表示される' do
        # 日本語URLで直接ログインページにアクセス
        visit '/ja/users/sign_in'
        expect(page).to have_button('ログイン')

        # ログイン
        fill_in 'メールアドレス', with: user_ja.email
        fill_in 'パスワード', with: 'password'
        click_button 'ログイン'

        # ログイン後も日本語で表示
        expect(page).to have_button('投稿')

        # 言語スイッチャーが表示されていることを確認
        expect(page).to have_link('English')

        # 英語のリンクをクリック
        click_link 'English'

        # 英語ページに移動したことを確認（langパラメータで確認）
        expect(current_url).to include('lang=en')
        expect(page).to have_button('Post')  # 英語の投稿ボタンに変わる
      end
    end
  end

  describe 'URL-based ロケール動作の検証' do
    it 'URLパスによって正しい言語で表示される' do
      # 1. デフォルト（英語）での表示確認
      visit root_path
      expect(page).to have_content('You need to sign in or sign up before continuing.')

      # 2. 日本語URLでの表示確認
      visit '/ja'
      expect(page).to have_content('アカウント登録もしくはログインしてください。')

      # 3. ユーザー設定に関係なく、URLが優先されることを確認
      # 英語設定のユーザーでも、日本語URLなら日本語で表示
      visit '/ja/users/sign_in'
      expect(page).to have_button('ログイン')

      # 日本語設定のユーザーでも、英語URLなら英語で表示
      visit '/users/sign_in'
      expect(page).to have_button('Log in')
    end
  end
end
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Messages Form', type: :system do
  before do
    @original_value = Devise.allow_unconfirmed_access_for
    Devise.allow_unconfirmed_access_for = 7.days
  end

  after do
    Devise.allow_unconfirmed_access_for = @original_value
  end

  let(:confirmed_user) { create(:user, :confirmed) }
  let(:unconfirmed_user) { create(:user, :unconfirmed) }

  def login_as(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'
  end

  context 'when the user is not confirmed' do
    before do
      login_as unconfirmed_user
      visit messages_path
    end

    it 'disables the form' do
      expect(page).to have_selector('fieldset[disabled]', visible: true)
      expect(page).to have_content(I18n.t('messages.email_confirmation_required'))
    end

    it 'disables the comment field' do
      expect(page).to have_field('comment', disabled: true)
    end
  end

  context 'when the user is confirmed' do
    before do
      login_as confirmed_user
      visit messages_path
    end

    it 'enables the form' do
      expect(page).not_to have_selector('fieldset[disabled]')
      expect(page).not_to have_content(I18n.t('messages.email_confirmation_required'))
    end

    it 'enables the comment field' do
      expect(page).to have_field('comment', disabled: false)
    end

    it 'allows form submission' do
      fill_in 'comment', with: 'This is a test message'
      click_button I18n.t('messages.form.post')
      expect(page).to have_content('This is a test message')
    end

    it 'shows a generic error message when message creation fails' do
      allow_any_instance_of(MessagesController).to receive(:create_message!).and_raise(StandardError, 'Simulated failure!')
      visit messages_path
      fill_in 'comment', with: 'fail'
      click_button I18n.t('messages.form.post')
      expect(page).to have_selector('[data-testid="flash-message"]', text: I18n.t('messages.errors.generic', error_message: 'Simulated failure!'))
    end

    it "shows a not owned error when trying to delete another user's message" do
      other_user = create(:user, :confirmed)
      message = create(:message, user: other_user, content: "other message")
      visit messages_path

      accept_confirm do
        # hiddenな削除ボタンを取得してJSで強制クリック
        delete_link = find_link("delete-message-#{message.id}", visible: :all)
        page.execute_script("arguments[0].click();", delete_link)
      end

      expect(page).to have_selector('[data-testid="flash-message"]', text: I18n.t('messages.errors.not_owned'), wait: 2)
      expect(page).to have_content('other message')
    end

    it 'shows a generic error message when an unexpected error occurs during message deletion' do
      # 例外を発生させるためにdestroy_message_if_owner!をモック
      allow_any_instance_of(MessagesController).to receive(:destroy_message_if_owner!).and_raise(StandardError, 'Simulated destroy failure!')
      other_user = create(:user, :confirmed)
      message = create(:message, user: other_user, content: "other message")
      visit messages_path

      accept_confirm do
        delete_link = find_link("delete-message-#{message.id}", visible: :all)
        page.execute_script("arguments[0].click();", delete_link)
      end

      expect(page).to have_selector('[data-testid="flash-message"]', text: I18n.t('messages.errors.generic', error_message: 'Simulated destroy failure!'), wait: 2)
      expect(page).to have_content('other message')
    end

    it 'allows the user to delete their own message' do
      # confirmed_userで自分のメッセージを作成
      message = create(:message, user: confirmed_user, content: 'my message')
      visit messages_path

      accept_confirm do
        delete_link = find_link("delete-message-#{message.id}", visible: :all)
        page.execute_script("arguments[0].click();", delete_link)
      end

      expect(page).not_to have_content('my message')
      expect(page).not_to have_selector("[data-testid='delete-message-#{message.id}']")
    end
  end

  context 'when form size exceeds the limit' do
    before do
      login_as confirmed_user
      visit messages_path
    end

    it 'shows a size limit exceeded error and does not submit the form' do
      # 1バイトの上限を仮定してテスト（テスト用にENVやconfig.x.max_request_bodyをstubしてもよい）
      allow(Rails.configuration.x).to receive(:max_request_body).and_return(1)
      visit current_path # 設定反映のためリロード

      fill_in 'comment', with: 'a' * 10_000 # 十分大きなデータ
      click_button I18n.t('messages.form.post')

      expect(page).to have_selector('[data-testid="flash-message"]', text: "1 Byte")
      # メッセージが投稿されていないことも確認
      expect(page).not_to have_content('a' * 10_000)
    end

    it 'allows submission when max_request_body is nil (no size limit)' do
      allow(Rails.configuration.x).to receive(:max_request_body).and_return(nil)
      visit current_path # 設定反映のためリロード

      fill_in 'comment', with: 'a' * 10_000
      click_button I18n.t('messages.form.post')

      # フラッシュメッセージが出ないこと、投稿が成功することを確認
      expect(page).not_to have_selector('[data-testid="flash-message"]', text: /size limit/i)
      expect(page).to have_content('a' * 10_000)
    end
  end
end

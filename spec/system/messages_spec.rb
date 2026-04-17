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

    it 'highlights a newly posted message until the user interacts with it' do
      create(:message, user: confirmed_user, content: 'Existing message')
      visit current_path

      existing_message = find('[data-message-id]', text: 'Existing message')
      existing_message_id = existing_message['data-message-id']
      existing_background = page.evaluate_script(
        "getComputedStyle(document.querySelector('[data-message-id=\"#{existing_message_id}\"]')).backgroundColor"
      )

      fill_in 'comment', with: 'Highlighted new message'
      click_button I18n.t('messages.form.post')

      new_message = find('[data-message-id]', text: 'Highlighted new message', wait: 5)
      new_message_id = new_message['data-message-id']
      new_background = page.evaluate_script(
        "getComputedStyle(document.querySelector('[data-message-id=\"#{new_message_id}\"]')).backgroundColor"
      )

      expect(new_message['data-new-message']).to eq('true')
      expect(new_background).not_to eq(existing_background)

      page.execute_script(<<~JS)
        const message = document.querySelector('[data-message-id="#{new_message_id}"]')
        message.dispatchEvent(new MouseEvent('mousemove', { bubbles: true }))
      JS

      cleared_background = page.evaluate_script(
        "getComputedStyle(document.querySelector('[data-message-id=\"#{new_message_id}\"]')).backgroundColor"
      )

      expect(page).to have_no_selector("[data-message-id='#{new_message_id}'][data-new-message='true']")
      expect(cleared_background).to eq(existing_background)
    end

    it 'queues messages from other users until the reveal line is clicked' do
      create(:message, user: confirmed_user, content: 'Older visible message')
      visit current_path

      expect(page).to have_css('#messages[data-channel-connected="true"]', wait: 5)
      reference_message = find('[data-message-id]', text: 'Older visible message')
      reference_message_id = reference_message['data-message-id']
      existing_background = page.evaluate_script(
        "getComputedStyle(document.querySelector('[data-message-id=\"#{reference_message_id}\"]')).backgroundColor"
      )

      other_user = create(:user, :confirmed)
      incoming_message_1 = create(:message, user: other_user, content: 'Incoming message one')
      incoming_message_2 = create(:message, user: other_user, content: 'Incoming message two')

      MessageBroadcastJob.perform_now(incoming_message_1.id)
      MessageBroadcastJob.perform_now(incoming_message_2.id)

      expect(page).to have_css('#new-messages-notice[data-pending-visible="true"] [data-role="new-messages-reveal"]', wait: 5)
      expect(page).not_to have_content('Incoming message one')
      expect(page).not_to have_content('Incoming message two')

      fill_in 'comment', with: 'My visible message'
      click_button I18n.t('messages.form.post')
      expect(page).to have_content('My visible message')

      first_child_id = page.evaluate_script("document.querySelector('#messages').firstElementChild.id")
      expect(first_child_id).to eq('new-messages-notice')

      find('[data-role="new-messages-reveal"]', visible: true).click

      message_one = find('[data-message-id]', text: 'Incoming message one')
      message_two = find('[data-message-id]', text: 'Incoming message two')
      background_one = page.evaluate_script(
        "getComputedStyle(document.querySelector('[data-message-id=\"#{message_one['data-message-id']}\"]')).backgroundColor"
      )
      background_two = page.evaluate_script(
        "getComputedStyle(document.querySelector('[data-message-id=\"#{message_two['data-message-id']}\"]')).backgroundColor"
      )

      expect(page).to have_css('[data-role="new-messages-separator"]', wait: 5)
      expect(page).to have_css('#new-messages-notice[data-pending-visible="false"]', wait: 5, visible: :all)
      expect(page.all('[data-role="new-messages-separator"]', visible: true).size).to eq(1)
      separator_has_message_above = page.evaluate_script(<<~JS)
        (() => {
          const sep = [...document.querySelectorAll('[data-role="new-messages-separator"]')].at(-1)
          return !!(sep && sep.previousElementSibling && sep.previousElementSibling.dataset && sep.previousElementSibling.dataset.messageId)
        })()
      JS
      expect(separator_has_message_above).to be(true)
      expect(background_one).not_to eq(existing_background)
      expect(background_two).not_to eq(existing_background)

      incoming_message_3 = create(:message, user: other_user, content: 'Incoming message three')
      MessageBroadcastJob.perform_now(incoming_message_3.id)

      first_child_role = page.evaluate_script("document.querySelector('#messages').firstElementChild.querySelector('[data-role]')?.dataset.role")
      expect(first_child_role).to eq('new-messages-reveal')
      expect(page).to have_css('[data-role="new-messages-separator"]', wait: 5)
      expect(page).not_to have_content('Incoming message three')

      find('[data-role="new-messages-reveal"]', visible: true).click
      expect(page).to have_content('Incoming message three')
      expect(page.all('[data-role="new-messages-separator"]', visible: true).size).to eq(2)
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

    it 'keeps deleted messages as tombstones with metadata' do
      other_user = create(:user, :confirmed, username: 'otheruser')
      message = create(:message, user: other_user, content: 'to be deleted')
      visit messages_path
      expect(page).to have_css('#messages[data-channel-connected="true"]', wait: 5)

      target = find("[data-message-id='#{message.id}']")
      expect(target).to have_content('to be deleted')
      expect(target).to have_content('otheruser')

      message.destroy!
      MessageBroadcastJob.perform_now(message.id)

      tombstone = find("[data-message-id='#{message.id}']", wait: 5)
      expect(tombstone['data-deleted-message']).to eq('true')
      expect(tombstone).to have_content(I18n.t('exports.message_deleted'))
      expect(tombstone).to have_content('otheruser')
      expect(tombstone).not_to have_content('to be deleted')
      expect(tombstone).to have_no_selector('[data-testid^="delete-message-"]')
    end

    it 'renders metadata checkboxes using user defaults' do
      confirmed_user.update(default_strip_metadata: false, default_allow_location_public: true)
      visit current_path

      expect(page).to have_unchecked_field('message_strip_metadata')
      expect(page).to have_checked_field('message_allow_location_public')
    end

    it 'allows posting after toggling metadata options' do
      visit current_path
      uncheck 'message_strip_metadata'
      check 'message_allow_location_public'
      fill_in 'comment', with: 'Metadata aware message'
      click_button I18n.t('messages.form.post')

      expect(page).to have_content('Metadata aware message')
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

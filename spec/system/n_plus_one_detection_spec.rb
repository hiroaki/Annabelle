require 'rails_helper'

RSpec.describe 'N+1 Detection', type: :system do
  def login_as(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'
  end

  context 'when displaying multiple messages' do
    it 'detects N+1 queries when eager loading is disabled' do
      # 複数のメッセージを作成（異なるユーザーで）
      users = create_list(:user, 3, :confirmed)
      users.each do |user|
        create(:message, user: user, content: "Message from #{user.username}")
      end

      # 一時的にeager loadingを無効化してN+1を発生させる
      allow(Message).to receive(:includes).and_return(Message)

      login_as users.first

      # Prosopiteが有効なら、N+1が検出されてエラーが発生する
      expect {
        visit messages_path
      }.to raise_error(Prosopite::NPlusOneQueriesError)
    end

    it 'does not detect N+1 queries when eager loading is enabled' do
      # 複数のメッセージを作成（異なるユーザーで）
      users = create_list(:user, 3, :confirmed)
      users.each do |user|
        create(:message, user: user, content: "Message from #{user.username}")
      end

      login_as users.first
      visit messages_path

      # eager loadingが有効なのでN+1は発生しない
      expect(page).to have_content("Message from")
    end
  end
end

require 'rails_helper'

RSpec.describe 'N+1 Detection', type: :system do
  let(:confirmed_user) { create(:user, :confirmed) }

  def login_as(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'
  end

  context 'when displaying multiple messages' do
    it 'detects N+1 queries for user associations' do
      # 複数のメッセージを作成（異なるユーザーで）
      users = create_list(:user, 3, :confirmed)
      users.each do |user|
        create(:message, user: user, content: "Message from #{user.username}")
      end

      login_as confirmed_user
      visit messages_path

      # Prosopiteが有効なら、N+1が検出されてエラーが出るはず
      expect(page).to have_content("Message from")
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OAuth Language Processing', type: :system, js: true do
  describe 'ログアウト後の言語保持' do
    let!(:user) { create(:user, preferred_language: 'ja') }

    before do
      login_as(user, scope: :user)
    end

    it '日本語設定ユーザーがログアウトしても日本語ページにリダイレクトされる' do
      # 日本語のページでログアウト
      visit '/ja'

      # ログアウトリンクをクリック
      find('[data-testid="current-user-signout"]').click

      # ログアウト後のページで日本語表示を確認
      expect(page).to have_button('ログイン')
    end
  end
end

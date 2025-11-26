require 'rails_helper'

RSpec.describe Users::PasswordsController, type: :request do
  let(:user) { create(:user) }

  describe 'GET /users/password/new' do
    context 'ログインしている場合' do
      before { sign_in user }

      it 'ログアウトしてパスワードリセット画面が表示される' do
        get new_user_password_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('You have been signed out to reset your password.')
      end
    end

    context 'ログインしていない場合' do
      it 'パスワードリセット画面が表示される' do
        get new_user_password_path
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('パスワード再設定のためログアウトしました。')
      end
    end
  end
end

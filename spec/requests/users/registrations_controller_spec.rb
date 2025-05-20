require 'rails_helper'

RSpec.describe Users::RegistrationsController, type: :request do
  let(:user) { create(:user, :confirmed, password: 'password') }
  let!(:authorization) { create(:authorization, user: user, provider: 'github', uid: '12345') }

  describe 'DELETE #unlink_oauth' do
    before { sign_in user }

    context '連携が存在し正常に削除できる場合' do
      it '成功メッセージでリダイレクトされる' do
        delete unlink_oauth_path(provider: 'github')
        expect(response).to redirect_to(edit_user_registration_path)
        follow_redirect!
        expect(response.body).to include(I18n.t('devise.registrations.unlink_oauth.success', provider_name: 'Github'))
        expect(user.authorizations.find_by(provider: 'github')).to be_nil
      end
    end

    context '連携が存在するが削除に失敗する場合' do
      before do
        allow_any_instance_of(Authorization).to receive(:destroy).and_return(false)
      end
      it '失敗メッセージでリダイレクトされる' do
        delete unlink_oauth_path(provider: 'github')
        expect(response).to redirect_to(edit_user_registration_path)
        follow_redirect!
        expect(response.body).to include(I18n.t('devise.registrations.unlink_oauth.failure', provider_name: 'Github'))
      end
    end

    context '連携が存在しない場合' do
      it 'not_foundメッセージでリダイレクトされる' do
        delete unlink_oauth_path(provider: 'twitter')
        expect(response).to redirect_to(edit_user_registration_path)
        follow_redirect!
        expect(response.body).to include(I18n.t('devise.registrations.unlink_oauth.not_found'))
      end
    end
  end

  describe 'PUT /users' do
    it '更新後に編集画面へリダイレクトされる' do
      sign_in user
      put user_registration_path, params: { user: { username: 'newname', current_password: 'password' } }
      expect(response).to redirect_to(edit_user_registration_path)
    end
  end

  # describe '#after_update_path_for' do
  #   it '編集画面へのパスを返す' do
  #     controller = described_class.new
  #     expect(controller.send(:after_update_path_for, user)).to eq(controller.send(:devise_edit_registration_path_for, user))
  #   end
  # end
end

require 'rails_helper'

RSpec.describe TwoFactorSettingsController, type: :request do
  around do |example|
    with_env(
      'ENABLE_2FA' => '1',
      'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY' => 'primary',
      'ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY' => 'det',
      'ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT' => 'salt'
    ) do
      example.run
    end
  end
  let(:user) { FactoryBot.create(:user, password: 'password123') }

  describe 'GET /two_factor_settings/new' do
    context 'when user is not signed in' do
      it 'redirects to sign in page' do
        get new_two_factor_settings_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is signed in' do
      before { sign_in user }

      context 'when 2FA is already enabled' do
        before { user.update(otp_required_for_login: true) }

        it 'redirects to dashboard with alert' do
          get new_two_factor_settings_path
          expect(response).to redirect_to(dashboard_path)
          expect(flash[:alert]).to eq(I18n.t('two_factor_settings.already_enabled'))
        end
      end

      context 'when 2FA is not enabled' do
        it 'renders the new template' do
          get new_two_factor_settings_path
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe 'GET /two_factor_settings/edit' do
    context 'when not signed in' do
      it 'redirects to sign in page' do
        get edit_two_factor_settings_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when 2FA is not enabled' do
        before { user.update(otp_required_for_login: false) }

        it 'redirects to new 2FA setup with alert' do
          get edit_two_factor_settings_path
          expect(response).to redirect_to(new_two_factor_settings_path)
          expect(flash[:alert]).to eq(I18n.t('two_factor_settings.enable_first'))
        end
      end

      context 'when 2FA is enabled' do
        before { user.update(otp_required_for_login: true) }

        context 'when backup codes already generated' do
          before do
            allow_any_instance_of(User).to receive(:two_factor_backup_codes_generated?).and_return(true)
          end

          it 'redirects to two factor authentication page with alert' do
            get edit_two_factor_settings_path
            expect(response).to redirect_to(two_factor_authentication_path)
            expect(flash[:alert]).to eq(I18n.t('two_factor_settings.backup_codes_already_seen'))
          end
        end

        context 'when backup codes not generated' do
          before do
            allow_any_instance_of(User).to receive(:two_factor_backup_codes_generated?).and_return(false)
            allow_any_instance_of(User).to receive(:generate_otp_backup_codes!).and_return(['code1', 'code2'])
            allow_any_instance_of(User).to receive(:save!).and_return(true)
          end

          it 'generates backup codes and renders edit' do
            get edit_two_factor_settings_path
            expect(response).to have_http_status(:ok)
            expect(response.body).to include('code1')
            expect(response.body).to include('code2')
          end
        end
      end
    end
  end

  describe 'POST /two_factor_settings' do
    before { sign_in user }

    let(:valid_params) do
      {
        two_fa: {
          code: '123456',
          password: 'password123'
        }
      }
    end

    context 'when password is incorrect' do
      it 'renders new with alert' do
        post two_factor_settings_path, params: { two_fa: { code: '123456', password: 'wrong' } }
        expect(response).to have_http_status(:found)
        follow_redirect!
        expect(response.body).to include(I18n.t('two_factor_settings.incorrect_password'))
      end
    end

    context 'when password is correct' do
      before do
        allow_any_instance_of(User).to receive(:valid_password?).and_return(true)
      end

      context 'when OTP code is valid' do
        before do
          allow_any_instance_of(User).to receive(:validate_and_consume_otp!).and_return(true)
          allow_any_instance_of(User).to receive(:enable_two_factor!).and_return(true)
        end

        it 'enables 2FA and redirects to edit with notice' do
          post two_factor_settings_path, params: valid_params
          expect(response).to redirect_to(edit_two_factor_settings_path)
          expect(flash[:notice]).to eq(I18n.t('two_factor_settings.enabled'))
        end
      end

      context 'when OTP code is invalid' do
        before do
          allow_any_instance_of(User).to receive(:validate_and_consume_otp!).and_return(false)
        end

        it 'renders new with alert' do
          post two_factor_settings_path, params: valid_params
          expect(response).to have_http_status(:found)
          follow_redirect!
          expect(response.body).to include(I18n.t('two_factor_settings.incorrect_code'))
        end
      end
    end
  end

  describe 'DELETE /two_factor_settings' do
    before { sign_in user }

    context 'when disable_two_factor! succeeds' do
      before do
        allow_any_instance_of(User).to receive(:disable_two_factor!).and_return(true)
      end

      it 'disables 2FA and redirects to authentication page with notice' do
        delete two_factor_settings_path
        expect(response).to redirect_to(two_factor_authentication_path)
        expect(flash[:notice]).to eq(I18n.t('two_factor_settings.disabled'))
      end
    end

    context 'when disable_two_factor! fails' do
      before do
        allow_any_instance_of(User).to receive(:disable_two_factor!).and_return(false)
      end

      it 'redirects to root with alert' do
        delete two_factor_settings_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t('two_factor_settings.could_not_disable'))
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Devise Mailer', type: :mailer do
  include ActionMailer::TestHelper

  let(:user) { create(:user, :unconfirmed, email: 'test@example.com') }
  let(:reset_token) { 'test_reset_token' }
  let(:confirmation_token) { 'test_confirmation_token' }
  let(:mailer_sender) { Devise.mailer_sender }

  # ActionMailerの設定から値を取得
  let(:mailer_url_options) { Rails.application.config.action_mailer.default_url_options }
  let(:host) { mailer_url_options[:host] }
  let(:port) { mailer_url_options[:port] }
  let(:protocol) { mailer_url_options[:protocol] || 'http' }
  let(:base_url) do
    url = "#{protocol}://#{host}"
    url += ":#{port}" if port.present? && port.to_s != '80' && port.to_s != '443'
    url
  end

  describe 'confirmation instructions email' do
    context 'in Japanese locale' do
      it 'renders without errors and includes locale parameter in URL' do
        I18n.with_locale(:ja) do
          mail = nil

          expect {
            mail = Devise::Mailer.confirmation_instructions(user, confirmation_token)
          }.not_to raise_error

          expect(mail.subject).to eq(I18n.t('devise.mailer.confirmation_instructions.subject'))
          expect(mail.to).to eq([user.email])
          expect(mail.from).to eq([mailer_sender])

          body = mail.body.to_s
          expect(body).to include("確認") # メール種別の大まかな判別
          expected_url = "#{base_url}/ja/users/confirmation?confirmation_token=#{confirmation_token}"
          expect(body).to include(expected_url)
        end
      end

      it 'can be delivered successfully' do
        I18n.with_locale(:ja) do
          mail = Devise::Mailer.confirmation_instructions(user, confirmation_token)

          expect {
            mail.deliver_now
          }.not_to raise_error

          expect(ActionMailer::Base.deliveries).not_to be_empty
          delivered_mail = ActionMailer::Base.deliveries.last
          expect(delivered_mail.to).to eq([user.email])
          expect(delivered_mail.subject).to eq(I18n.t('devise.mailer.confirmation_instructions.subject'))
          expect(delivered_mail.from).to eq([mailer_sender])
        end
      end
    end

    context 'in English locale' do
      it 'renders without errors and includes locale parameter in URL' do
        I18n.with_locale(:en) do
          mail = nil

          expect {
            mail = Devise::Mailer.confirmation_instructions(user, confirmation_token)
          }.not_to raise_error

          expect(mail.subject).to eq(I18n.t('devise.mailer.confirmation_instructions.subject'))
          expect(mail.to).to eq([user.email])
          expect(mail.from).to eq([mailer_sender])

          body = mail.body.to_s
          expect(body).to include("confirm") # メール種別の大まかな判別
          expected_url = "#{base_url}/en/users/confirmation?confirmation_token=#{confirmation_token}"
          expect(body).to include(expected_url)
        end
      end

      it 'can be delivered successfully' do
        I18n.with_locale(:en) do
          mail = Devise::Mailer.confirmation_instructions(user, confirmation_token)

          expect {
            mail.deliver_now
          }.not_to raise_error

          expect(ActionMailer::Base.deliveries).not_to be_empty
          delivered_mail = ActionMailer::Base.deliveries.last
          expect(delivered_mail.to).to eq([user.email])
          expect(delivered_mail.subject).to eq(I18n.t('devise.mailer.confirmation_instructions.subject'))
          expect(delivered_mail.from).to eq([mailer_sender])
        end
      end
    end
  end

  describe 'reset password instructions email' do
    context 'in Japanese locale' do
      it 'renders without errors and includes locale parameter in URL' do
        I18n.with_locale(:ja) do
          mail = nil

          expect {
            mail = Devise::Mailer.reset_password_instructions(user, reset_token)
          }.not_to raise_error

          expect(mail.subject).to eq(I18n.t('devise.mailer.reset_password_instructions.subject'))
          expect(mail.to).to eq([user.email])
          expect(mail.from).to eq([mailer_sender])

          body = mail.body.to_s
          expect(body).to include("パスワード") # メール種別の大まかな判別
          expected_url = "#{base_url}/ja/users/password/edit?reset_password_token=#{reset_token}"
          expect(body).to include(expected_url)
        end
      end

      it 'can be delivered successfully' do
        I18n.with_locale(:ja) do
          mail = Devise::Mailer.reset_password_instructions(user, reset_token)

          expect {
            mail.deliver_now
          }.not_to raise_error

          expect(ActionMailer::Base.deliveries).not_to be_empty
          delivered_mail = ActionMailer::Base.deliveries.last
          expect(delivered_mail.to).to eq([user.email])
          expect(delivered_mail.subject).to eq(I18n.t('devise.mailer.reset_password_instructions.subject'))
          expect(delivered_mail.from).to eq([mailer_sender])
        end
      end
    end

    context 'in English locale' do
      it 'renders without errors and includes locale parameter in URL' do
        I18n.with_locale(:en) do
          mail = nil

          expect {
            mail = Devise::Mailer.reset_password_instructions(user, reset_token)
          }.not_to raise_error

          expect(mail.subject).to eq(I18n.t('devise.mailer.reset_password_instructions.subject'))
          expect(mail.to).to eq([user.email])
          expect(mail.from).to eq([mailer_sender])

          body = mail.body.to_s
          expect(body).to include("password") # メール種別の大まかな判別
          expected_url = "#{base_url}/en/users/password/edit?reset_password_token=#{reset_token}"
          expect(body).to include(expected_url)
        end
      end

      it 'can be delivered successfully' do
        I18n.with_locale(:en) do
          mail = Devise::Mailer.reset_password_instructions(user, reset_token)

          expect {
            mail.deliver_now
          }.not_to raise_error

          expect(ActionMailer::Base.deliveries).not_to be_empty
          delivered_mail = ActionMailer::Base.deliveries.last
          expect(delivered_mail.to).to eq([user.email])
          expect(delivered_mail.subject).to eq(I18n.t('devise.mailer.reset_password_instructions.subject'))
          expect(delivered_mail.from).to eq([mailer_sender])
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Devise Mailer Integration', type: :request do
  include ActionMailer::TestHelper

  before do
    ActionMailer::Base.deliveries.clear
  end

  describe 'user registration flow' do
    it 'sends confirmation email without errors and includes locale parameter' do
      user_params = {
        email: 'newuser@example.com',
        username: 'newuser123',
        password: 'password123',
        password_confirmation: 'password123'
      }

      perform_enqueued_jobs do
        expect {
          post user_registration_path, params: { user: user_params }
        }.not_to raise_error
      end

      expect(response).to have_http_status(:see_other) # redirects to sign in page
      expect(ActionMailer::Base.deliveries.size).to eq(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to include('newuser@example.com')
      expect(mail.subject).to match(/確認|Confirm/i)

      # メール本文にlocaleパラメータが含まれていることを確認
      body = mail.body.to_s
      expect(body).to match(/\/(en|ja)\/users\/confirmation/)

      # 実際のURLが正しい形式であることを確認
      mailer_options = Rails.application.config.action_mailer.default_url_options
      expected_host = mailer_options[:host]
      expected_protocol = mailer_options[:protocol] || 'http'
      expect(body).to include("#{expected_protocol}://#{expected_host}")
    end

    it 'handles different locales correctly' do
      user_params = {
        email: 'jauser@example.com',
        username: 'jauser123',
        password: 'password123',
        password_confirmation: 'password123'
      }

      perform_enqueued_jobs do
        expect {
          post user_registration_path(locale: :ja), params: { user: user_params }
        }.not_to raise_error
      end

      expect(ActionMailer::Base.deliveries.size).to eq(1)
      mail = ActionMailer::Base.deliveries.last
      body = mail.body.to_s
      expect(body).to include('/ja/users/confirmation')
    end
  end

  describe 'password reset flow' do
    let(:existing_user) { create(:user, :confirmed) }

    it 'sends password reset email without errors and includes locale parameter' do
      perform_enqueued_jobs do
        expect {
          post user_password_path, params: { user: { email: existing_user.email } }
        }.not_to raise_error
      end

      expect(response).to have_http_status(:see_other) # redirects back
      expect(ActionMailer::Base.deliveries.size).to eq(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to include(existing_user.email)
      expect(mail.subject).to match(/パスワード|Reset password|password/i)

      # メール本文にlocaleパラメータが含まれていることを確認
      body = mail.body.to_s
      expect(body).to match(/\/(en|ja)\/users\/password\/edit/)

      # 実際のURLが正しい形式であることを確認
      mailer_options = Rails.application.config.action_mailer.default_url_options
      expected_host = mailer_options[:host]
      expected_protocol = mailer_options[:protocol] || 'http'
      expect(body).to include("#{expected_protocol}://#{expected_host}")
    end

    it 'handles different locales correctly for password reset' do
      perform_enqueued_jobs do
        expect {
          post user_password_path(locale: :ja), params: { user: { email: existing_user.email } }
        }.not_to raise_error
      end

      expect(ActionMailer::Base.deliveries.size).to eq(1)
      mail = ActionMailer::Base.deliveries.last
      body = mail.body.to_s
      expect(body).to include('/ja/users/password/edit')
    end
  end
end

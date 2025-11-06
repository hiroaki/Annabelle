require 'rails_helper'

RSpec.describe 'Basic Auth', type: :request do
  let(:user) { 'testuser' }
  let(:password) { 'testpass' }
  let(:headers) { {} }



  def basic_auth_header(username, password)
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
    { 'HTTP_AUTHORIZATION' => credentials }
  end

  describe 'GET /' do
    subject { get '/', headers: headers }

    context 'when both BASIC_AUTH_USER and BASIC_AUTH_PASSWORD are not set' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:valid_user).and_return(nil)
        allow_any_instance_of(ApplicationController).to receive(:valid_pswd).and_return(nil)
      end

      it 'allows access without authentication' do
        subject
        expect(response).not_to have_http_status(:unauthorized)
        expect(response).not_to have_http_status(:forbidden)
      end
    end

    context 'when only BASIC_AUTH_USER is set' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:valid_user).and_return(user)
        allow_any_instance_of(ApplicationController).to receive(:valid_pswd).and_return(nil)
      end

      it 'allows access without authentication' do
        subject
        expect(response).not_to have_http_status(:unauthorized)
        expect(response).not_to have_http_status(:forbidden)
      end
    end

    context 'when only BASIC_AUTH_PASSWORD is set' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:valid_user).and_return(nil)
        allow_any_instance_of(ApplicationController).to receive(:valid_pswd).and_return(password)
      end

      it 'allows access without authentication' do
        subject
        expect(response).not_to have_http_status(:unauthorized)
        expect(response).not_to have_http_status(:forbidden)
      end
    end

    context 'when both BASIC_AUTH_USER and BASIC_AUTH_PASSWORD are set' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:valid_user).and_return(user)
        allow_any_instance_of(ApplicationController).to receive(:valid_pswd).and_return(password)
      end

      context 'without credentials' do
        it 'denies access' do
          subject
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'with correct credentials' do
        let(:headers) { basic_auth_header(user, password) }
        it 'allows access' do
          subject
          expect(response).not_to have_http_status(:unauthorized)
          expect(response).not_to have_http_status(:forbidden)
        end
      end

      context 'with incorrect credentials' do
        let(:headers) { basic_auth_header(user, 'wrong') }
        it 'denies access' do
          subject
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end

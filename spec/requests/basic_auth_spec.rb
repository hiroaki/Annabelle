require 'rails_helper'

RSpec.describe 'Basic Auth', type: :request do
  let(:pair1_user) { 'pair_user_1' }
  let(:pair1_password) { 'pair_pass_1' }
  let(:pair2_user) { 'pair_user_2' }
  let(:pair2_password) { 'pair_pass_2' }
  let(:headers) { {} }
  let(:env_vars) do
    {
      'ENABLED_BASIC_AUTH' => nil,
      'BASIC_AUTH_PAIRS' => nil
    }
  end

  around do |example|
    with_env(env_vars) { example.run }
  end

  def basic_auth_header(username, password)
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
    { 'HTTP_AUTHORIZATION' => credentials }
  end

  describe 'GET /' do
    subject { get '/', headers: headers }

    context 'when no basic auth env is set' do
      let(:env_vars) { super() }

      it 'allows access without authentication' do
        subject
        expect(response).not_to have_http_status(:unauthorized)
        expect(response).not_to have_http_status(:forbidden)
      end
    end

    context 'when BASIC_AUTH_PAIRS includes multiple pairs but ENABLED_BASIC_AUTH is not set' do
      let(:env_vars) do
        super().merge(
          'BASIC_AUTH_PAIRS' => "#{pair1_user}:#{pair1_password},#{pair2_user}:#{pair2_password}"
        )
      end

      it 'skips basic auth because the feature flag is not enabled' do
        subject
        expect(response).not_to have_http_status(:unauthorized)
        expect(response).not_to have_http_status(:forbidden)
      end
    end

    context 'when ENABLED_BASIC_AUTH is true and BASIC_AUTH_PAIRS is malformed' do
      let(:env_vars) do
        super().merge(
          'ENABLED_BASIC_AUTH' => '1',
          'BASIC_AUTH_PAIRS' => 'invalid_format'
        )
      end

      let(:headers) { basic_auth_header('any', 'any') }

      it 'fails closed and denies access' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when ENABLED_BASIC_AUTH is true and BASIC_AUTH_PAIRS is missing' do
      let(:env_vars) do
        super().merge(
          'ENABLED_BASIC_AUTH' => '1'
        )
      end

      it 'fails closed and denies access' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when ENABLED_BASIC_AUTH is false and BASIC_AUTH_PAIRS is set' do
      let(:env_vars) do
        super().merge(
          'ENABLED_BASIC_AUTH' => 'false',
          'BASIC_AUTH_PAIRS' => "#{pair1_user}:#{pair1_password}"
        )
      end

      it 'skips basic auth' do
        subject
        expect(response).not_to have_http_status(:unauthorized)
        expect(response).not_to have_http_status(:forbidden)
      end
    end

    context 'when ENABLED_BASIC_AUTH is blank and BASIC_AUTH_PAIRS is set' do
      let(:env_vars) do
        super().merge(
          'ENABLED_BASIC_AUTH' => '',
          'BASIC_AUTH_PAIRS' => "#{pair1_user}:#{pair1_password}"
        )
      end

      it 'skips basic auth because blank is treated as unset' do
        subject
        expect(response).not_to have_http_status(:unauthorized)
        expect(response).not_to have_http_status(:forbidden)
      end
    end

    context 'when ENABLED_BASIC_AUTH is true and BASIC_AUTH_PAIRS contains separator whitespace' do
      let(:env_vars) do
        super().merge(
          'ENABLED_BASIC_AUTH' => '1',
          'BASIC_AUTH_PAIRS' => "#{pair1_user}:#{pair1_password}, #{pair2_user}:#{pair2_password}"
        )
      end

      context 'with second pair credentials' do
        let(:headers) { basic_auth_header(pair2_user, pair2_password) }

        it 'allows access' do
          subject
          expect(response).not_to have_http_status(:unauthorized)
          expect(response).not_to have_http_status(:forbidden)
        end
      end
    end

    context 'when ENABLED_BASIC_AUTH is true and BASIC_AUTH_PAIRS includes multiple pairs' do
      let(:env_vars) do
        super().merge(
          'ENABLED_BASIC_AUTH' => '1',
          'BASIC_AUTH_PAIRS' => "#{pair1_user}:#{pair1_password},#{pair2_user}:#{pair2_password}"
        )
      end

      context 'without credentials' do
        it 'denies access' do
          subject
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'with first pair credentials' do
        let(:headers) { basic_auth_header(pair1_user, pair1_password) }

        it 'allows access' do
          subject
          expect(response).not_to have_http_status(:unauthorized)
          expect(response).not_to have_http_status(:forbidden)
        end
      end

      context 'with second pair credentials' do
        let(:headers) { basic_auth_header(pair2_user, pair2_password) }

        it 'allows access' do
          subject
          expect(response).not_to have_http_status(:unauthorized)
          expect(response).not_to have_http_status(:forbidden)
        end
      end

      context 'with invalid credentials' do
        let(:headers) { basic_auth_header(pair2_user, 'wrong') }

        it 'denies access' do
          subject
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end

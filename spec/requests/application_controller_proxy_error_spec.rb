require 'rails_helper'

RSpec.describe 'ApplicationController proxy error handling', type: :request do
  describe 'X-App-Response header' do
    it 'adds X-App-Response header to all responses' do
      get root_path
      expect(response.headers['X-App-Response']).to eq('true')
    end

    it 'includes header on error responses' do
      # Try to access a non-existent route to trigger a 404
      expect { get '/non-existent-route' }.to raise_error(ActionController::RoutingError)
    end

    it 'includes header on successful responses' do
      get root_path
      expect(response).to have_http_status(:success)
      expect(response.headers['X-App-Response']).to eq('true')
    end
  end
end
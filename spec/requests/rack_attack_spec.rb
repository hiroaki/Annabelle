require 'rails_helper'

RSpec.describe 'Rack::Attack', type: :request do
  let(:ban_cache_key) { 'rack:attack:ban:127.0.0.1' }

  around do |example|
    original_enabled = Rack::Attack.enabled
    original_store = Rack::Attack.cache.store
    test_store = ActiveSupport::Cache::MemoryStore.new

    Rack::Attack.enabled = true
    Rack::Attack.cache.store = test_store
    Rack::Attack.reset!

    example.run
  ensure
    Rack::Attack.reset!
    test_store.clear
    Rack::Attack.cache.store = original_store
    Rack::Attack.enabled = original_enabled
  end

  it 'returns 429 on throttle without affecting the health check path' do
    throttle = Rack::Attack.throttles.fetch('req/ip:get')
    throttle_limit = throttle.limit
    throttle_period = throttle.period

    throttle_limit.times do
      get '/'
      expect(response).to have_http_status(:moved_permanently)
    end

    get '/'

    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers['Retry-After']).to eq(throttle_period.to_s)
    expect(response.headers['X-Rack-Attack-Match-Type']).to be_nil
    expect(response.headers['X-Rack-Attack-Match-Name']).to be_nil
    expect(JSON.parse(response.body)).to eq(
      'error' => 'throttled',
      'message' => 'Rate limit exceeded, retry after some time'
    )
    expect(Rack::Attack.cache.store.read(ban_cache_key)).to be_nil

    get rails_health_check_path

    expect(response).to have_http_status(:ok)
  end

  it 'immediately caches a ban when probing env-like paths' do
    get '/.env'

    expect(response).to have_http_status(:forbidden)
    expect(response.headers['Retry-After']).to eq('600')
    expect(response.headers['X-Rack-Attack-Match-Type']).to be_nil
    expect(response.headers['X-Rack-Attack-Match-Name']).to be_nil
    expect(JSON.parse(response.body)).to eq(
      'error' => 'forbidden',
      'message' => 'Access denied due to suspicious activity'
    )
    expect(Rack::Attack.cache.store.read(ban_cache_key)).to eq('1')

    get rails_health_check_path

    expect(response).to have_http_status(:forbidden)
    expect(response.headers['Retry-After']).to eq('600')
    expect(response.headers['X-Rack-Attack-Match-Type']).to be_nil
    expect(response.headers['X-Rack-Attack-Match-Name']).to be_nil
    expect(JSON.parse(response.body)).to eq(
      'error' => 'forbidden',
      'message' => 'Access denied due to suspicious activity'
    )
  end

  it 'does not ban ordinary paths that merely contain env in the filename' do
    get '/foo.env'

    expect(response).not_to have_http_status(:forbidden)
    expect(Rack::Attack.cache.store.read(ban_cache_key)).to be_nil
  end
end

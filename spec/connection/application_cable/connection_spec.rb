require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :connection do
  include ActionCable::Connection::TestCase::Behavior
  include ActionCable::Connection::Assertions

  tests ApplicationCable::Connection

  let(:user) { create(:user) }
  let(:warden) { instance_double(Warden::Proxy, user: warden_user) }

  context 'when the session is authenticated' do
    let(:warden_user) { user }

    it 'connects successfully' do
      connect '/cable', env: { 'warden' => warden }

      expect(connection.current_user).to eq(user)
    end
  end

  context 'when the session is not authenticated' do
    let(:warden_user) { nil }

    it 'rejects the connection' do
      assert_reject_connection { connect '/cable', env: { 'warden' => warden } }
    end
  end
end

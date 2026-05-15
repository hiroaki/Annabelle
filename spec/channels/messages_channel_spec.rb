require 'rails_helper'

RSpec.describe MessagesChannel, type: :channel do
  let(:user) { create(:user) }

  it 'subscribes authenticated users to the general message board' do
    stub_connection current_user: user

    subscribe

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from('general_message_board')
  end
end

require 'rails_helper'

class DummyFactory
  include Factory
end

RSpec.describe Factory, type: :model do
  let(:factory) { DummyFactory.new }
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let!(:message) { create(:message, user: user) }

  before do
    allow(MessageBroadcastJob).to receive(:perform_later)
  end

  describe '#create_message!' do
    it 'creates a message and enqueues MessageBroadcastJob' do
      params = attributes_for(:message).merge(user_id: user.id)
      expect {
        factory.create_message!(params)
      }.to change(Message, :count).by(1)
      expect(MessageBroadcastJob).to have_received(:perform_later).with(Message.last.id)
    end
  end

  describe '#destroy_message!' do
    it 'destroys the message and enqueues MessageBroadcastJob' do
      expect {
        factory.destroy_message!(message.id)
      }.to change(Message, :count).by(-1)
      expect(MessageBroadcastJob).to have_received(:perform_later).with(message.id)
    end
  end

  describe '#destroy_message_if_owner!' do
    it 'destroys the message if user is owner and enqueues MessageBroadcastJob' do
      msg = create(:message, user: user)
      expect {
        factory.destroy_message_if_owner!(msg.id, user)
      }.to change(Message, :count).by(-1)
      expect(MessageBroadcastJob).to have_received(:perform_later).with(msg.id)
    end

    it 'raises MessageNotOwnedError if user is not owner' do
      msg = create(:message, user: other_user)
      expect {
        factory.destroy_message_if_owner!(msg.id, user)
      }.to raise_error(Factory::MessageNotOwnedError)
      expect(Message.exists?(msg.id)).to be true
    end

    it 'raises MessageNotOwnedError if user is not a User' do
      msg = create(:message, user: user)
      expect {
        factory.destroy_message_if_owner!(msg.id, nil)
      }.to raise_error(Factory::MessageNotOwnedError)
      expect(Message.exists?(msg.id)).to be true
    end
  end
end

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

    it 'attaches provided uploads' do
      file = fixture_file_upload('test_image.jpg', 'image/jpeg')
      params = {
        content: 'with attachment',
        user_id: user.id,
        attachements: [file]
      }

      expect {
        factory.create_message!(params)
      }.to change(ActiveStorage::Attachment, :count).by(1)

      message = Message.order(created_at: :desc).first
      expect(message.attachements.size).to eq(1)
    end

    it 'logs a warning when an invalid signed blob id is provided' do
      params = attributes_for(:message).merge(user_id: user.id, attachements: ['invalid-signed-id'])

      # Force the blob lookup to raise so we exercise the rescue/logging path
      allow(ActiveStorage::Blob).to receive(:find_signed).and_raise(ActiveSupport::MessageVerifier::InvalidSignature)

      expect(Rails.logger).to receive(:warn).with(/find_blob_from_signed_id/)

      factory.create_message!(params)
    end

    context 'with metadata handling' do
      before do
        allow(ExtractImageMetadataJob).to receive(:perform_later)
      end

      it 'records upload_settings in blob metadata' do
        file = fixture_file_upload('test_image.jpg', 'image/jpeg')
        params = {
          content: 'with metadata',
          user_id: user.id,
          attachements: [file],
          strip_metadata: true,
          allow_location_public: false
        }

        factory.create_message!(params)
        blob = Message.last.attachements.last.blob

        expect(blob.metadata['upload_settings']).to eq({
          'strip_metadata' => true,
          'allow_location_public' => false
        })
      end

      it 'creates ImageMetadataAction audit log' do
        file = fixture_file_upload('test_image.jpg', 'image/jpeg')
        params = {
          content: 'with audit',
          user_id: user.id,
          attachements: [file],
          strip_metadata: true,
          allow_location_public: false,
          ip_address: '127.0.0.1',
          user_agent: 'Test Browser'
        }

        expect {
          factory.create_message!(params)
        }.to change(ImageMetadataAction, :count).by(1)

        action = ImageMetadataAction.last
        expect(action.user).to eq(user)
        expect(action.strip_metadata).to be true
        expect(action.allow_location_public).to be false
        expect(action.ip_address).to eq('127.0.0.1')
        expect(action.user_agent).to eq('Test Browser')
      end

      it 'enqueues ExtractImageMetadataJob' do
        file = fixture_file_upload('test_image.jpg', 'image/jpeg')
        params = {
          content: 'with exif job',
          user_id: user.id,
          attachements: [file]
        }

        factory.create_message!(params)
        blob = Message.last.attachements.last.blob

        expect(ExtractImageMetadataJob).to have_received(:perform_later).with(blob.id)
      end

      it 'invokes ImageMetadata::Stripper when strip_metadata is requested' do
        file = fixture_file_upload('test_image.jpg', 'image/jpeg')
        params = {
          content: 'with stripper call',
          user_id: user.id,
          attachements: [file],
          strip_metadata: true
        }

        allow(ImageMetadata::Stripper).to receive(:strip).and_call_original

        factory.create_message!(params)

        expect(ImageMetadata::Stripper).to have_received(:strip).at_least(:once)
      end
    end
  end

  describe '#attach_files (private)' do
    let(:message_without_metadata) { create(:message, user: user) }

    it 'attaches normalized uploads without metadata handling' do
      file = fixture_file_upload('test_image_proper.jpg', 'image/jpeg')

      expect {
        factory.send(:attach_files, message_without_metadata, [file])
      }.to change(message_without_metadata.attachements, :count).by(1)
    ensure
      message_without_metadata.attachements.purge
    end

    it 'skips nil attachments gracefully' do
      expect {
        factory.send(:attach_files, message_without_metadata, [nil])
      }.not_to change(message_without_metadata.attachements, :count)
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

  describe '#normalize_attachment (private)' do
    # Test the private method indirectly through create_message!

    it 'accepts and attaches an ActiveStorage::Blob directly' do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join('spec/fixtures/files/test_image.jpg')),
        filename: 'blob_test.jpg',
        content_type: 'image/jpeg'
      )

      params = {
        content: 'with blob',
        user_id: user.id,
        attachements: [blob]
      }

      msg = factory.create_message!(params)
      expect(msg.attachements.size).to eq(1)
      expect(msg.attachements.first.blob).to eq(blob)
    end

    it 'accepts and attaches a valid signed blob id' do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join('spec/fixtures/files/test_image.jpg')),
        filename: 'signed_test.jpg',
        content_type: 'image/jpeg'
      )
      signed_id = blob.signed_id

      params = {
        content: 'with signed id',
        user_id: user.id,
        attachements: [signed_id]
      }

      msg = factory.create_message!(params)
      expect(msg.attachements.size).to eq(1)
      expect(msg.attachements.first.blob).to eq(blob)
    end

    it 'accepts and attaches a Hash with io and filename' do
      file_path = Rails.root.join('spec/fixtures/files/test_image.jpg')

      attachable_hash = {
        'io' => File.open(file_path),
        'filename' => 'hash_test.jpg',
        'content_type' => 'image/jpeg'
      }

      params = {
        content: 'with hash',
        user_id: user.id,
        attachements: [attachable_hash]
      }

      msg = factory.create_message!(params)
      expect(msg.attachements.size).to eq(1)
      expect(msg.attachements.first.filename.to_s).to eq('hash_test.jpg')
    end

    it 'skips nil attachments without error' do
      params = {
        content: 'with nil',
        user_id: user.id,
        attachements: [nil]
      }

      msg = factory.create_message!(params)
      expect(msg.attachements.size).to eq(0)
    end

    it 'skips invalid signed ids without raising' do
      params = {
        content: 'with invalid id',
        user_id: user.id,
        attachements: ['invalid-signature-blob-id']
      }

      expect {
        msg = factory.create_message!(params)
        expect(msg.attachements.size).to eq(0)
      }.not_to raise_error
    end
  end

  describe '#image_file? (private)' do
    it 'returns true when attachable responds to content_type with an image MIME' do
      attachable = double('Attachable', content_type: 'image/png')
      expect(factory.send(:image_file?, attachable)).to be true
    end

    it 'returns false when attachable lacks content_type information' do
      attachable = Object.new
      expect(factory.send(:image_file?, attachable)).to be false
    end
  end
end

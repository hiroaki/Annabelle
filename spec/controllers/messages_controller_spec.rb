require 'rails_helper'

RSpec.describe MessagesController, type: :controller do
  describe '#create' do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it 'strips blank entries from attachment params before calling create_message!' do
      file = fixture_file_upload('test_image.jpg', 'image/jpeg')
      captured = nil

      allow(controller).to receive(:create_message!) do |params|
        captured = params
        build(:message)
      end

      post :create, params: {
        locale: :en,
        content: 'with attachment',
        attachments: ['', file]
      }, format: :turbo_stream

      expect(captured).not_to be_nil
      attachments = Array.wrap(captured[:attachments])
      expect(attachments.length).to eq(1)
      expect(attachments.first).to be_a(ActionDispatch::Http::UploadedFile)
    end

    it 'applies user defaults when metadata params are missing' do
      user.update(default_strip_metadata: false, default_allow_location_public: true)
      captured = nil

      allow(controller).to receive(:create_message!) do |params|
        captured = params
        build(:message)
      end

      post :create, params: { locale: :en, content: 'hello world' }, format: :turbo_stream

      expect(captured[:strip_metadata]).to be false
      expect(captured[:allow_location_public]).to be true
    end

    it 'casts metadata params to booleans' do
      captured = nil

      allow(controller).to receive(:create_message!) do |params|
        captured = params
        build(:message)
      end

      post :create, params: {
        locale: :en,
        content: 'hello world',
        strip_metadata: '0',
        allow_location_public: '1'
      }, format: :turbo_stream

      expect(captured[:strip_metadata]).to be false
      expect(captured[:allow_location_public]).to be true
    end
  end
end

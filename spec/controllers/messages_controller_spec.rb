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
        attachements: ['', file]
      }, format: :turbo_stream

      expect(captured).not_to be_nil
      attachments = Array.wrap(captured[:attachements])
      expect(attachments.length).to eq(1)
      expect(attachments.first).to be_a(ActionDispatch::Http::UploadedFile)
    end
  end
end

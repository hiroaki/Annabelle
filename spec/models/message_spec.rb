require 'rails_helper'

RSpec.describe Message, type: :model do
  include ActiveJob::TestHelper

  around do |example|
    perform_enqueued_jobs { example.run }
  end
  describe "アソシエーション" do
    it "user に属していること" do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end

    it "attachments を持っていること" do
      message = build(:message)
      expect(message).to respond_to(:attachments)
    end
  end

  describe "ファイルの添付" do
    it "ファイルを添付できること" do
      message = create(:message)
      file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'sample.txt'), 'text/plain')
      message.attachments.attach(file)
      expect(message.attachments.count).to eq(1)
    end

    it "EXIF付き画像を添付した場合、blobのmetadataにEXIF情報が格納されること" do
      message = create(:message)
      image = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'image_with_gps.jpg'), 'image/jpeg')
      message.attachments.attach(image)

      blob = message.attachments.last.blob
      blob.analyze
      blob.reload

      extracted = blob.metadata.fetch('exif', {})
      expect(extracted).not_to be_empty
      expect(extracted).to include('gps', 'datetime', 'camera')
      expect(extracted['gps']['latitude']).to be_within(0.000001).of(35.681236)
      expect(extracted['gps']['longitude']).to be_within(0.000001).of(139.767125)
      # EXIF datetime strings use the `YYYY:MM:DD HH:MM:SS` format.
      # The analyzer preserves the EXIF textual value; assert it directly.
      expect(extracted['datetime']).to eq('2025:01:02 03:04:05')
      expect(extracted['camera']).to eq({ 'make' => 'ExampleCam', 'model' => 'Imaginary 1' })
    end
  end
end

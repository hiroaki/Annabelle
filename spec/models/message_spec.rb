require 'rails_helper'

RSpec.describe Message, type: :model do
  include ActiveJob::TestHelper

  describe "基本機能" do
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

  describe "削除時の添付ファイル自動削除" do
    before do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it "Message を削除すると purge ジョブがenqueueされ、実行後にAttachment/Blobが削除される" do
      Prosopite.pause do
        user = create(:user)
        message = create(:message, user: user)

        blob1 = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('file-1'),
          filename: 'file1.txt',
          content_type: 'text/plain'
        )
        blob2 = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('file-2'),
          filename: 'file2.txt',
          content_type: 'text/plain'
        )

        message.attachments.attach([blob1, blob2])

        # まず、destroy によって PurgeJob が enqueue されることを確認
        expect {
          message.destroy
        }.to have_enqueued_job(ActiveStorage::PurgeJob).exactly(2).times

        # DB 側の関連レコード（ActiveStorage::Attachment）が消えていることも確認
        expect(ActiveStorage::Attachment.where(record: message).exists?).to be false

        # purge_later は非同期なので、ここでジョブを明示的に実行
        perform_enqueued_jobs

        # Blob 自体も（他レコードで共有されていない前提で）消えることを確認
        expect(ActiveStorage::Blob.where(id: [blob1.id, blob2.id]).exists?).to be false
      end
    end

    it "添付がない場合は PurgeJob を enqueue しない" do
      message = create(:message)
      expect { message.destroy }.not_to have_enqueued_job(ActiveStorage::PurgeJob)
    end

    it "同一Blobが他レコードに添付されている場合は Blob は削除されない" do
      user = create(:user)
      m1 = create(:message, user: user)
      m2 = create(:message, user: user)

      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new('x'), filename: 'x.txt', content_type: 'text/plain')
      m1.attachments.attach(blob)
      m2.attachments.attach(blob)

      expect { m1.destroy }.to have_enqueued_job(ActiveStorage::PurgeJob).once

      perform_enqueued_jobs

      expect(ActiveStorage::Attachment.where(record: m1)).not_to exist
      expect(ActiveStorage::Attachment.where(record: m2)).to exist
      expect(ActiveStorage::Blob.where(id: blob.id)).to exist
    end
  end
end

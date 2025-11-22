# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExtractImageMetadataJob, type: :job do
  describe '#perform' do
    it 'EXIF データを抽出して blob metadata に保存すること' do
      blob = create_blob_with_image('image_with_gps.jpg')

      expect {
        described_class.new.perform(blob.id)
      }.to change { blob.reload.metadata.key?('exif') }.from(false).to(true)

      extracted = blob.metadata['exif']
      expect(extracted['gps']['latitude']).to be_within(0.000001).of(35.681236)
      expect(extracted['gps']['longitude']).to be_within(0.000001).of(139.767125)
    ensure
      blob.purge
    end

    it 'EXIF データがない画像では metadata を更新しないこと' do
      blob = create_blob_with_image('test_image_proper.jpg')
      original_metadata = blob.metadata.dup

      described_class.new.perform(blob.id)

      blob.reload
      expect(blob.metadata).to eq(original_metadata)
    ensure
      blob.purge
    end

    it 'JPEG 以外の画像では処理をスキップすること' do
      blob = create_blob_with_image('test_image_proper.png', content_type: 'image/png')

      expect {
        described_class.new.perform(blob.id)
      }.not_to change { blob.reload.metadata }
    ensure
      blob.purge
    end

    it '存在しない blob_id でエラーにならないこと' do
      expect {
        described_class.new.perform(99999)
      }.not_to raise_error
    end

    it 'EXIF 解析に失敗してもエラーにならないこと' do
      blob = create_blob_with_image('image_with_gps.jpg')
      allow_any_instance_of(ActiveStorage::Analyzer::ExifAnalyzer).to receive(:metadata).and_raise(StandardError, 'Parse error')

      expect {
        described_class.new.perform(blob.id)
      }.not_to raise_error
    ensure
      blob.purge
    end
  end

  def create_blob_with_image(filename, content_type: 'image/jpeg')
    path = Rails.root.join('spec/fixtures/files', filename)
    File.open(path, 'rb') do |file|
      ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: filename,
        content_type: content_type
      )
    end
  end
end

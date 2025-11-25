require 'rails_helper'

RSpec.describe ImageMetadata::Stripper, type: :service do
  describe '.strip_and_upload' do
    let(:user) { create(:user) }

    it 'uploads a large in-memory file without raising and persists metadata' do
      # Create a temporary large binary file at test runtime (5 MB)
      size_mb = 5
      tmp = Tempfile.new(['large_test', '.jpg'])
      tmp.binmode
      size_mb.times { tmp.write("\0" * 1_048_576) } # write 1MB chunks
      tmp.rewind

      metadata = { 'upload_settings' => { 'strip_metadata' => true, 'allow_location_public' => false } }

      attachable = { io: tmp, filename: 'large_test.jpg', content_type: 'image/jpeg' }

      blob = nil
      expect {
        blob = ImageMetadata::Stripper.strip_and_upload(attachable, metadata: metadata)
      }.not_to raise_error

      expect(blob).to be_present
      expect(blob.byte_size).to eq(size_mb * 1_048_576)
      expect(blob.metadata['upload_settings']).to eq(metadata['upload_settings'])

      # Clean up uploaded blob and tempfile
      blob.purge if blob
      tmp.close!
    end

    it 'accepts an existing blob and creates a new stripped blob' do
      # Create a small source blob to simulate existing upload
      source_blob = ActiveStorage::Blob.create_and_upload!(io: File.open(Rails.root.join('spec/fixtures/files/test_image.jpg')), filename: 'src.jpg', content_type: 'image/jpeg')

      metadata = { 'upload_settings' => { 'strip_metadata' => true } }
      new_blob = ImageMetadata::Stripper.strip_and_upload(source_blob, metadata: metadata)

      expect(new_blob).to be_present
      expect(new_blob.id).not_to eq(source_blob.id)
      expect(new_blob.metadata['upload_settings']).to eq(metadata['upload_settings'])

      # cleanup
      new_blob.purge if new_blob
      source_blob.purge if source_blob
    end

    context 'error handling' do
      it 'logs a warning and returns nil if an exception occurs' do
        attachable = { io: StringIO.new('test'), filename: 'test.jpg', content_type: 'image/jpeg' }
        allow(described_class).to receive(:strip).and_raise(StandardError, 'Simulated failure')

        expect(Rails.logger).to receive(:warn).with(/strip_and_upload failed: StandardError: Simulated failure/)
        expect(described_class.strip_and_upload(attachable)).to be_nil
      end

      it 'returns nil if stripping fails to produce a valid IO' do
        attachable = { io: StringIO.new('test'), filename: 'test.jpg', content_type: 'image/jpeg' }
        # Simulate strip returning something invalid or nil so it falls through to the final nil return
        allow(described_class).to receive(:strip).and_return(nil)

        expect(described_class.strip_and_upload(attachable)).to be_nil
      end
    end
  end
end

describe ImageMetadata::Stripper do
  describe '.strip' do
    let(:fixture_path) { Rails.root.join('spec/fixtures/files/image_with_gps.jpg') }

    context 'with a valid image attachable' do
      let(:io) { File.open(fixture_path, 'rb') }
      let(:attachable) do
        {
          io: io,
          filename: 'image_with_gps.jpg',
          content_type: 'image/jpeg'
        }
      end

      after do
        io.close
      end

      it 'returns a new attachable whose IO has no EXIF metadata' do
        result = nil
        result = described_class.strip(attachable)

        expect(result[:io]).not_to eq(attachable[:io])
        expect(result[:filename]).to eq('image_with_gps.jpg')

        result[:io].rewind
        image = MiniMagick::Image.read(result[:io].read)
        expect(image.exif).to eq({})
      ensure
        result[:io].close! if result&.dig(:io).is_a?(Tempfile)
      end
    end

    context 'when attachable is missing IO' do
      it 'returns the original attachable unchanged' do
        attachable = { filename: 'no-io.jpg', content_type: 'image/jpeg' }
        expect(described_class.strip(attachable)).to eq(attachable)
      end
    end

    context 'when processing fails' do
      it 'falls back to the original IO' do
        io = StringIO.new('not-an-image')
        attachable = { io: io, filename: 'bad', content_type: 'image/jpeg' }

        allow(described_class).to receive(:process_with_vips).and_raise(StandardError)
        allow(described_class).to receive(:process_with_image_processing_minimagick).and_return(nil)
        allow(described_class).to receive(:process_with_minimagick).and_return(nil)

        result = described_class.strip(attachable)
        expect(result).to eq(attachable)
        expect(io.pos).to eq(0)
      end
    end

    context 'when all processors return nil' do
      it 'rewinds the original io and returns attachable unchanged' do
        io = StringIO.new('image-data')
        io.read # advance pointer to ensure method rewinds
        attachable = { io: io, filename: 'still-original.jpg', content_type: 'image/jpeg' }

        allow(described_class).to receive(:process_with_vips).and_return(nil)
        allow(described_class).to receive(:process_with_image_processing_minimagick).and_return(nil)
        allow(described_class).to receive(:process_with_minimagick).and_return(nil)

        result = described_class.strip(attachable)

        expect(result).to eq(attachable)
        expect(io.pos).to eq(0)
      end
    end

    context 'when filename lacks extension' do
      it 'infers the extension from content type' do
        io = StringIO.new('binary-image-data')
        attachable = { io: io, filename: 'upload', content_type: 'image/png' }
        captured_ext = nil

        allow(described_class).to receive(:process_with_vips).and_return(nil)
        allow(described_class).to receive(:process_with_image_processing_minimagick) do |data, ext|
          captured_ext = ext
          nil
        end
        allow(described_class).to receive(:process_with_minimagick).and_return(nil)

        described_class.strip(attachable)

        expect(captured_ext).to eq('png')
      end
    end

    context 'when neither filename nor content type provide image extension' do
      it 'falls back to jpg' do
        io = StringIO.new('binary-data')
        attachable = { io: io, filename: 'upload', content_type: 'application/octet-stream' }
        captured_ext = nil

        allow(described_class).to receive(:process_with_vips).and_return(nil)
        allow(described_class).to receive(:process_with_image_processing_minimagick) do |_, ext|
          captured_ext = ext
          nil
        end
        allow(described_class).to receive(:process_with_minimagick).and_return(nil)

        described_class.strip(attachable)

        expect(captured_ext).to eq('jpg')
      end
    end

    context 'when MiniMagick backend raises' do
      it 'logs the failure and returns the original attachable' do
        io = StringIO.new('image-data')
        attachable = { io: io, filename: 'sample.jpg', content_type: 'image/jpeg' }

        allow(ImageMetadata::Stripper).to receive(:process_with_vips).and_return(nil)
        allow(ImageMetadata::Stripper).to receive(:process_with_image_processing_minimagick).and_return(nil)
        allow(MiniMagick::Image).to receive(:read).and_raise(StandardError.new('boom'))

        expect(Rails.logger).to receive(:info).with(/MiniMagick failed/)

        result = described_class.strip(attachable)

        expect(result).to eq(attachable)
      end
    end
  end
end

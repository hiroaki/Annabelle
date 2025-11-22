require 'rails_helper'
require 'stringio'

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

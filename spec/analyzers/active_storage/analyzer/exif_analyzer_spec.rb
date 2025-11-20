# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorage::Analyzer::ExifAnalyzer do
  describe ".accept?" do
    it "accepts JPEG images" do
      blob = ActiveStorage::Blob.new(content_type: "image/jpeg")
      allow(blob).to receive(:image?).and_return(true)

      expect(described_class.accept?(blob)).to be true
    end

    it "rejects non-JPEG images" do
      blob = ActiveStorage::Blob.new(content_type: "image/png")
      allow(blob).to receive(:image?).and_return(true)

      expect(described_class.accept?(blob)).to be false
    end
  end

  describe "#metadata" do
    it "extracts gps, datetime, and camera information when present" do
      blob = create_blob("image_with_gps.jpg")

      metadata = described_class.new(blob).metadata

      expect(metadata).to include(:width, :height, :extracted_metadata)
      extracted = metadata[:extracted_metadata]
      expect(extracted[:gps][:latitude]).to be_within(0.000001).of(35.681236)
      expect(extracted[:gps][:longitude]).to be_within(0.000001).of(139.767125)
      expect(extracted[:datetime]).to eq("2025-01-02T03:04:05+09:00")
      expect(extracted[:camera]).to eq({ make: "ExampleCam", model: "Imaginary 1" })
    ensure
      blob.purge
    end

    it "returns an empty hash when no EXIF data exists" do
      blob = create_blob("test_image_proper.jpg")

      metadata = described_class.new(blob).metadata
      expect(metadata).to include(:width, :height)
      expect(metadata).not_to include(:extracted_metadata)
    ensure
      blob.purge
    end

    it "returns an empty hash when parsing fails" do
      blob = create_blob("image_with_gps.jpg")
      allow(::EXIFR::JPEG).to receive(:new).and_raise(::EXIFR::MalformedJPEG.new("bad data"))

      metadata = described_class.new(blob).metadata
      expect(metadata).to include(:width, :height)
      expect(metadata).not_to include(:extracted_metadata)
    ensure
      blob.purge
    end
  end

  def create_blob(filename, content_type: "image/jpeg")
    path = Rails.root.join("spec/fixtures/files", filename)
    File.open(path, "rb") do |file|
      ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: filename,
        content_type: content_type
      )
    end
  end
end

# frozen_string_literal: true

require "exifr/jpeg"

class ActiveStorage::Analyzer::ExifAnalyzer < ActiveStorage::Analyzer
  SUPPORTED_CONTENT_TYPES = %w[image/jpeg image/jpg image/pjpeg].freeze

  class << self
    def accept?(blob)
      blob.image? && SUPPORTED_CONTENT_TYPES.include?(blob.content_type)
    end
  end

  def metadata
    return {} unless self.class.accept?(blob)

    download_blob_to_tempfile do |file|
      build_metadata(file)
    end
  rescue ::EXIFR::MalformedJPEG, ::EOFError, ::ArgumentError => error
    log_debug(error)
    {}
  end

  private

  def build_metadata(file)
    exif = ::EXIFR::JPEG.new(file.path)
    extracted = {}

    gps = extract_gps(exif)
    extracted[:gps] = gps if gps

    datetime = exif.date_time_original || exif.date_time || exif.date_time_digitized
    extracted[:datetime] = datetime&.iso8601 if datetime

    camera = extract_camera(exif)
    extracted[:camera] = camera if camera

    extracted.empty? ? {} : { extracted_metadata: extracted }
  end

  def extract_gps(exif)
    return unless exif&.gps

    latitude = exif.gps.latitude
    longitude = exif.gps.longitude
    return unless latitude && longitude

    { latitude: latitude.to_f, longitude: longitude.to_f }
  end

  def extract_camera(exif)
    make = normalized_string(exif&.make)
    model = normalized_string(exif&.model)

    camera = {}
    camera[:make] = make if make
    camera[:model] = model if model
    camera.empty? ? nil : camera
  end

  def normalized_string(value)
    string = value.to_s.strip
    string.empty? ? nil : string
  end

  def log_debug(error)
    return unless defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger

    Rails.logger.debug { "[ExifAnalyzer] #{error.class}: #{error.message}" }
  end
end

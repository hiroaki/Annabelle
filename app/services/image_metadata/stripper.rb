# frozen_string_literal: true

require 'stringio'

module ImageMetadata
  # Strips EXIF/IPTC metadata from an attachable image IO using the best
  # available backend. Prefers ruby-vips via ImageProcessing when available and
  # falls back to ImageProcessing::MiniMagick or plain MiniMagick. Environments
  # that do not include certain backends simply skip them without raising.
  module Stripper
    module_function

    # @param attachable [Hash] Active Storage attachable hash
    # @return [Hash] new attachable whose IO references a Tempfile with stripped metadata
    def strip(attachable)
      return attachable unless strip_target?(attachable)

      io = attachable[:io]
      filename = attachable[:filename] || 'upload'
      content_type = attachable[:content_type]

      io.rewind if io.respond_to?(:rewind)
      data = io.read
      ext = preferred_extension(filename, content_type)

      tempfile = process_with_vips(data, ext) ||
                 process_with_image_processing_minimagick(data, ext) ||
                 process_with_minimagick(data, ext)

      if tempfile
        attachable.merge(io: tempfile, filename: filename, content_type: content_type)
      else
        io.rewind if io.respond_to?(:rewind)
        attachable
      end
    rescue => e
      Rails.logger.warn("[ImageMetadata::Stripper] strip failed: #{e.class}: #{e.message}")
      io.rewind if io.respond_to?(:rewind)
      attachable
    end

    def strip_target?(attachable)
      attachable.is_a?(Hash) && attachable[:io]
    end
    private_class_method :strip_target?

    def preferred_extension(filename, content_type)
      ext = File.extname(filename).to_s.downcase.delete_prefix('.')
      return ext if ext.present?

      if content_type.to_s.start_with?('image/')
        content_type.split('/').last.to_s
      else
        'jpg'
      end
    end
    private_class_method :preferred_extension

    # This branch requires the host OS to have libvips and the ruby-vips
    # extension installed. CI/lint environments often omit those native
    # dependencies, so we exclude it from coverage to avoid flaky builds.
    # :nocov:
    def process_with_vips(data, ext)
      return unless defined?(ImageProcessing::Vips) && defined?(Vips)

      image = Vips::Image.new_from_buffer(data, '')
      buffer = image.write_to_buffer(".#{ext}", strip: true)
      tempfile_from_buffer(buffer, ".#{ext}")
    rescue LoadError, StandardError => e
      Rails.logger.info("[ImageMetadata::Stripper] vips processing unavailable: #{e.class}: #{e.message}")
      nil
    end
    private_class_method :process_with_vips
    # :nocov:

    # This branch depends on ImageMagick binaries being present and
    # discoverable by MiniMagick. Because contributors' environments vary
    # (especially on macOS/CI), we treat it as un-coverable in practice.
    # :nocov:
    def process_with_image_processing_minimagick(data, ext)
      return unless defined?(ImageProcessing::MiniMagick)

      source = ImageProcessing::MiniMagick.source(StringIO.new(data))
      tempfile = source.convert(ext).strip.call
      tempfile.binmode if tempfile.respond_to?(:binmode)
      tempfile.rewind if tempfile.respond_to?(:rewind)
      tempfile
    rescue LoadError, StandardError => e
      Rails.logger.info("[ImageMetadata::Stripper] ImageProcessing::MiniMagick failed: #{e.class}: #{e.message}")
      nil
    end
    private_class_method :process_with_image_processing_minimagick
    # :nocov:

    def process_with_minimagick(data, ext)
      return unless defined?(MiniMagick)

      image = MiniMagick::Image.read(data)
      image.strip
      blob = image.to_blob
      tempfile_from_buffer(blob, ensure_extension(ext))
    rescue LoadError, StandardError => e
      Rails.logger.info("[ImageMetadata::Stripper] MiniMagick failed: #{e.class}: #{e.message}")
      nil
    end
    private_class_method :process_with_minimagick

    def tempfile_from_buffer(buffer, extension)
      tmp = Tempfile.new(['stripped', extension])
      tmp.binmode
      tmp.write(buffer)
      tmp.rewind
      tmp
    end
    private_class_method :tempfile_from_buffer

    def ensure_extension(ext)
      ext.start_with?('.') ? ext : ".#{ext}"
    end
    private_class_method :ensure_extension
  end
end

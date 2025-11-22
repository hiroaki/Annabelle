module Factory
  # Factory concern for message creation/destruction and attachment handling.
  #
  # Design intent and background:
  # - This module centralizes the low-level operations used by controllers to create
  #   messages and manage their associated Active Storage attachments while keeping
  #   higher-level controllers thin. It focuses on ensuring uploads are attached in
  #   a predictable, transactional manner and that broadcasting happens after the
  #   database commit.
  #
  # - Historically we observed a race where Active Storage's analyzer would attempt
  #   to open blob files before the underlying service write was durably persisted
  #   (especially when jobs are executed inline in test environments). To avoid
  #   relying on brittle timing assumptions, this code extracts attachment params
  #   and explicitly attaches sanitized upload objects inside the same transaction
  #   that creates the Message record. Broadcasting and other side-effects are
  #   enqueued after the transaction completes.
  #
  # - We deliberately keep parameter normalization at the controller boundary
  #   (e.g. `MessagesController#message_params`) so callers always pass a clean
  #   payload. The Factory only handles attachment semantics (removing the key
  #   and turning values into attachables) and defensive conversions for a few
  #   accepted input shapes (UploadedFile, signed blob id, already-built attachable).
  #
  # - This concern favors being explicit about attachment timing and content to
  #   make future work (e.g. metadata extraction, audit records) rely on a
  #   consistent and testable upload lifecycle.

  MessageNotOwnedError = Class.new(StandardError)

  # Create a Message and attach files inside a transaction, then enqueue a
  # broadcast job after the transaction commits.
  #
  # Intent / rationale:
  # - Attachments are removed from `params` first (via `extract_attachements`) so
  #   ActiveRecord won't attempt to auto-attach during `create!`. This avoids the
  #   scenario where empty or malformed entries in `params[:attachements]` would
  #   cause spurious blobs or analyzer errors.
  # - The attach step is executed within the same database transaction so the
  #   association exists atomically with the message creation; subsequent jobs
  #   may rely on the message and attachments being present in the DB.
  # - Broadcasting (`MessageBroadcastJob`) is enqueued after creation so that
  #   consumers rendering the message can safely find the persisted attachments.
  # - Image metadata handling: strip_metadata/allow_location_public settings are
  #   recorded in blob.metadata['upload_settings'] and ImageMetadataAction audit log.
  #   EXIF extraction runs asynchronously via ExtractImageMetadataJob.
  def create_message!(params)
    # Extract metadata handling params (optional)
    strip_metadata = params.delete(:strip_metadata)
    allow_location_public = params.delete(:allow_location_public)
    ip_address = params.delete(:ip_address)
    user_agent = params.delete(:user_agent)

    attachments = extract_attachements(params)

    message = nil
    Message.transaction do
      message = Message.create!(params)
      attach_files_with_metadata_handling(
        message,
        attachments,
        strip_metadata: strip_metadata,
        allow_location_public: allow_location_public,
        ip_address: ip_address,
        user_agent: user_agent
      )
    end

    MessageBroadcastJob.perform_later(message.id)

    message
  end

  # Destroy a message (no ownership checks) and notify via broadcast.
  #
  # Rationale:
  # - This method mirrors the original behavior: it removes the record and then
  #   enqueues a broadcast indicating the deletion so front-end clients can
  #   update their state. It intentionally leaves authorization to callers.
  def destroy_message!(id)
    message = Message.find(id)
    message.destroy!
    MessageBroadcastJob.perform_later(message.id)
  end

  # Destroys a message only if the given user owns it; otherwise raises.
  #
  # Intent:
  # - Provide an explicit check that the `user` is the owner before destroying
  #   so controllers can call this helper for authenticated deletion flows.
  def destroy_message_if_owner!(id, user)
    Message.find(id).tap do |message|
      if !user.is_a?(User) || message.user_id != user.id
        raise MessageNotOwnedError, 'The message user destroying does not belong to the specified user.'
      end

      message.destroy!
      MessageBroadcastJob.perform_later(message.id)
    end
  end

  private

    # Extracts and removes the `attachements` entry from the provided params.
    #
    # Background & rationale:
    # - The controller is expected to sanitize `attachements` (remove empty
    #   strings) before calling the Factory. This method's responsibility is
    #   limited to removing the key so `Message.create!(params)` doesn't trigger
    #   any automatic attach behavior, and to normalize the value to an Array so
    #   the attach loop can uniformly iterate.
    # - We accept both symbol and string keys to be defensive toward different
    #   caller types (PermittedParameters vs plain Hash).
    def extract_attachements(params)
      raw = params.delete(:attachements)
      raw = params.delete('attachements') if raw.nil? && params.respond_to?(:key?)
      Array.wrap(raw)
    end

    # Iterate over provided uploads and attach them to the message.
    #
    # Why this explicit loop?
    # - We convert a few common upload shapes (UploadedFile, signed
    #   blob ids, already-built attachable hashes) into the attachable forms
    #   Active Storage expects. Doing this explicitly prevents accidental
    #   creation of empty/invalid blobs and makes the behavior deterministic for
    #   downstream jobs and tests.
    def attach_files(message, attachments)
      attachments.each do |upload|
        attachable = normalize_attachment(upload)
        next if attachable.nil?

        message.attachements.attach(attachable)
      end
    end

    # Attach files with metadata handling (strip, audit log, EXIF extraction).
    #
    # This method extends attach_files with:
    # - Recording upload_settings in blob.metadata
    # - Creating ImageMetadataAction audit log
    # - Enqueuing ExtractImageMetadataJob for async EXIF extraction
    #
    # Note: strip_metadata processing is not yet implemented (requires image_processing gem).
    def attach_files_with_metadata_handling(message, attachments, strip_metadata:, allow_location_public:, ip_address:, user_agent:)
      attachments.each do |upload|
        attachable = normalize_attachment(upload)
        next if attachable.nil?

        if strip_metadata && image_file?(attachable)
          attachable = ImageMetadata::Stripper.strip(attachable)
        end

        message.attachements.attach(attachable)
        attachment = message.attachements.last
        blob = attachment.blob

        # Store upload settings in blob metadata
        if strip_metadata || allow_location_public
          blob.update(metadata: blob.metadata.merge(
            'upload_settings' => {
              'strip_metadata' => strip_metadata || false,
              'allow_location_public' => allow_location_public || false
            }
          ))
        end

        # Record audit log
        ImageMetadataAction.create!(
          user: message.user,
          blob_id: blob.key,
          action: 'upload',
          strip_metadata: strip_metadata || false,
          allow_location_public: allow_location_public || false,
          ip_address: ip_address,
          user_agent: user_agent
        )

        # Enqueue EXIF extraction job
        ExtractImageMetadataJob.perform_later(blob.id)
      end
    end

    # Convert an incoming upload representation into an Active Storage
    # attachable suitable for `message.attachements.attach`.
    #
    # Supported shapes and reasoning:
    # - ActiveStorage::Blob or Attachment: returned as-is (already a persisted
    #   blob/attachment).
    # - ActionDispatch::Http::UploadedFile (or similar): we extract `tempfile`
    #   and `original_filename` and return a Hash `{ io:, filename:, content_type: }`.
    #   We rewind the tempfile to ensure the IO is readable from the start.
    # - String values: treated as signed blob IDs and resolved to a Blob via
    #   `find_blob_from_signed_id`. Invalid signed IDs are ignored (nil).
    # - Hash-like objects that respond to `deep_symbolize_keys` are passed
    #   through after symbolizing keys to allow explicit attachable hashes.
    #
    # This defensive conversion centralizes attachable normalization and
    # documents the accepted inputs for future contributors.
    def normalize_attachment(upload)
      return upload if upload.is_a?(ActiveStorage::Blob) || upload.is_a?(ActiveStorage::Attachment)

      if upload.respond_to?(:tempfile) && upload.respond_to?(:original_filename)
        io = upload.tempfile
        io.rewind if io.respond_to?(:rewind)

        return {
          io: io,
          filename: upload.original_filename,
          content_type: upload.content_type
        }
      end

      if upload.is_a?(String)
        return find_blob_from_signed_id(upload)
      end

      if upload.respond_to?(:deep_symbolize_keys)
        return upload.deep_symbolize_keys
      end

      nil
    end

    # Return true if the attachable appears to be an image based on content_type
    def image_file?(attachable)
      content_type = if attachable.is_a?(Hash)
                       attachable[:content_type].to_s
      elsif attachable.respond_to?(:content_type)
                       attachable.content_type.to_s
      else
                       ''
      end

      content_type.start_with?('image')
    end

    # Resolve a signed blob id to an ActiveStorage::Blob.
    #
    # Rationale:
    # - Forms or APIs may include previously-created signed blob ids (direct
    #   upload flows). We attempt to resolve them; if invalid or missing, we
    #   return nil so callers can safely skip them rather than raising and
    #   interrupting user-facing flows.
    def find_blob_from_signed_id(value)
      ActiveStorage::Blob.find_signed(value)
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound => e
      truncated = value.to_s[0, 64]
      Rails.logger.warn("[Factory] find_blob_from_signed_id: failed to resolve signed blob (value=#{truncated}...): #{e.class}: #{e.message}")
      nil
    end
end

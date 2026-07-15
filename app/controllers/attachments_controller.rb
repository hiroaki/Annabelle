class AttachmentsController < ApplicationController
  include ActiveStorage::Streaming

  before_action :authenticate_user!

  def metadata
    attachment = find_message_attachment
    return render json: {}, status: :not_found if attachment.nil?

    options = helpers.image_location_options(attachment)
    render json: options[:data] || {}
  end

  def show
    attachment = find_message_attachment
    return head :not_found if attachment.nil?

    stream_blob(attachment.blob, disposition: :inline)
  end

  def download
    attachment = find_message_attachment
    return head :not_found if attachment.nil?

    stream_blob(attachment.blob, disposition: :attachment)
  end

  def representation
    attachment = find_message_attachment
    return head :not_found if attachment.nil?
    return head :not_found unless attachment.representable?

    representation = attachment.representation(variation_transformations).processed

    http_cache_forever public: false do
      send_blob_stream representation, disposition: params[:disposition] || 'inline'
    end
  rescue ActiveStorage::InvariableError,
         ActiveStorage::UnrepresentableError,
         ActiveStorage::UnpreviewableError,
         ActiveSupport::MessageVerifier::InvalidSignature
    head :not_found
  end

  private

    def find_message_attachment
      attachment = ActiveStorage::Attachment.find(params[:id])
      return attachment if attachment.record.is_a?(Message)

      nil
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def stream_blob(blob, disposition:)
      if request.headers['Range'].present?
        send_blob_byte_range_data blob, request.headers['Range']
      else
        http_cache_forever public: false do
          response.headers['Accept-Ranges'] = 'bytes'
          response.headers['Content-Length'] = blob.byte_size.to_s

          send_blob_stream blob, disposition: disposition
        end
      end
    end

    def variation_transformations
      ActiveStorage::Variation.decode(params[:variation_key]).transformations
    end
end

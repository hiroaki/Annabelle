class AttachmentsController < ApplicationController
  before_action :authenticate_user!

  def metadata
    attachment = ActiveStorage::Attachment.find(params[:id])
    # Note: In a real application with private rooms, you should check
    # if current_user can view attachment.record (the message).
    # Since this app is a public board for logged-in users, we just check authentication.

    options = helpers.image_location_options(attachment)
    render json: options[:data] || {}
  rescue ActiveRecord::RecordNotFound
    render json: {}, status: :not_found
  end
end

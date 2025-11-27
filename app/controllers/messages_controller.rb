class MessagesController < ApplicationController
  include Factory

  helper_method :strip_metadata_preference, :allow_location_public_preference

  before_action :authenticate_user!
  before_action :require_confirmed_user_for_non_safe_requests

  def index
    set_messages
  end

  def create
    create_message!(message_params.merge(user: current_user, ip_address: request.remote_ip, user_agent: request.user_agent))
  rescue => ex
    flash.now.alert = I18n.t('messages.errors.generic', error_message: ex.message)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update('flash-storage', partial: 'shared/flash_storage') }
      format.html { render :index, status: :unprocessable_content }
    end
  end

  def destroy
    destroy_message_if_owner!(params[:id], current_user)
  rescue MessageNotOwnedError
    flash.now.alert = I18n.t('messages.errors.not_owned')
    set_messages
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.update('flash-storage', partial: 'shared/flash_storage')
      }
      format.html { render :index, status: :unprocessable_content }
    end
  rescue => ex
    flash.now.alert = I18n.t('messages.errors.generic', error_message: ex.message)
    set_messages
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update('flash-storage', partial: 'shared/flash_storage') }
      format.html { render :index, status: :unprocessable_content }
    end
  end

  private

    def message_params
      permitted = params.permit(:content, attachments: [])
      if permitted.key?(:attachments)
        # Remove empty file entries (browsers may submit "") to avoid treating them as uploads.
        permitted[:attachments] = Array.wrap(permitted[:attachments]).compact_blank
      end
      permitted[:strip_metadata] = strip_metadata_preference
      permitted[:allow_location_public] = allow_location_public_preference
      permitted
    end

    def require_confirmed_user_for_non_safe_requests
      return if request.get? || request.head?
      return if current_user.confirmed?

      render plain: 'Email confirmation required', status: :forbidden
    end

    def set_messages
      @messages = Message.includes(:user, attachments_attachments: :blob).order(created_at: :desc).page(params[:page])
    end

    def strip_metadata_preference
      metadata_flag_from_params(:strip_metadata, current_user.default_strip_metadata)
    end

    def allow_location_public_preference
      metadata_flag_from_params(:allow_location_public, current_user.default_allow_location_public)
    end

    def metadata_flag_from_params(key, default)
      boolean_type = ActiveModel::Type::Boolean.new
      if params.key?(key)
        raw_value = params[key]
        raw_value = raw_value.last if raw_value.is_a?(Array)
        return boolean_type.cast(raw_value)
      end

      default
    end

  public
end

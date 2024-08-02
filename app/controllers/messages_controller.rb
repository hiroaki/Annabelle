class MessagesController < ApplicationController
  include Factory

  def index
    @messages = Message.all.limit(25).order(created_at: :desc)
  end

  def create
    create_message!(message_params)
  rescue => ex
    flash.now.notice = "Error: #{ex.message}"
  end

  def destroy
    destroy_message!(params[:id])
  rescue => ex
    flash.now.notice = "Error: #{ex.message}"
  end

  private

    def message_params
        params.permit(:content, attachements: [])
    end
end

class MessagesController < ApplicationController
  include Factory

  def show
    @messages = Message.all.limit(5).order(created_at: :desc)
  end

  def create
    create_message!(message_params)
    # redirect_to action: :show
    head :ok
  end

  private

    def message_params
        params.permit(:content)
    end
end

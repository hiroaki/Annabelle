class MessagesController < ApplicationController
  def show
    @messages = Message.all.limit(5).order(created_at: :desc)
  end

  def create
    msg = Message.create!(message_params)

    ActionCable.server.broadcast('hoge',
      ApplicationController.renderer.render(partial: 'messages/message', locals: { message: msg })
    )

    redirect_to action: :show
  end

  private

    def message_params
        params.permit(:content)
    end
end

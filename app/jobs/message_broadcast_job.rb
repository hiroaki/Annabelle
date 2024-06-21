class MessageBroadcastJob < ApplicationJob
  include MessagesHelper

  queue_as :default

  def perform(*args)
    instance_of_message = args[0]
    ActionCable.server.broadcast('general_message_board', { rendered_message: render_message(instance_of_message) })
  end
end

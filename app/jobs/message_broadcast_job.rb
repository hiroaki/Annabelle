class MessageBroadcastJob < ApplicationJob
  queue_as :default

  def render_message(message)
    ApplicationController.renderer.render(partial: 'messages/message', locals: { message: message, as_new: true })
  end

  def perform(*args)
    # NOTE: perform_later での呼び出し時は、オブジェクトをシリアライズ／デシリアライズする都合で
    # Message.find が実行されるため削除されているオブジェクトを再利用できません。
    # また保存される内容も id だけで足りるため、args[0] には Message.id を受けるようにしています。
    message_id = args[0]
    message = Message.find_by_id(message_id)

    if message.nil?
      ActionCable.server.broadcast('general_message_board', {
        destroyed: message_id
      })
    else
      ActionCable.server.broadcast('general_message_board', {
        created: message_id,
        rendered_message: render_message(message)
      })
    end
  end
end

module Factory
  MessageNotOwnedError = Class.new(StandardError)

  def create_message!(params)
    message = Message.create!(params)
    MessageBroadcastJob.perform_later(message.id)
  end

  def destroy_message!(id)
    message = Message.find(id)
    message.destroy!
    MessageBroadcastJob.perform_later(message.id)
  end

  def destroy_message_if_owner!(id, user)
    Message.find(id).tap do |message|
      if !user.kind_of?(User) || message.user_id != user.id
        raise MessageNotOwnedError, 'The message user destroying does not belong to the specified user.'
      end

      message.destroy!
      MessageBroadcastJob.perform_later(message.id)
    end
  end
end

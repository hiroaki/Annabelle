class CurrentUserPresenter < ModelPresenterBase
  def self.username_display_dom_id
    'user-name-display'
  end

  def initialize(view_context, model)
    model = User.new if model.nil?

    if !model.kind_of?(User)
      raise ArgumentError, "Expected User, got #{model.class.name}"
    end

    super
  end

  def user
    model
  end

  def meta_tag
    return '' unless view_context.user_signed_in?

    view_context.tag.meta(name: 'current-user-id', content: user.id)
  end

  def links
    return '' unless view_context.user_signed_in?

    view_context.safe_join([
      view_context.link_to(
        user.username,
        view_context.user_path(user),
        class: 'text-gray-400',
        id: self.class.username_display_dom_id,
        **view_context.data_with_testid('current-user-display'),
      ),
      view_context.link_to(
        I18n.t('layouts.configuration_menu.sign_out'),
        view_context.destroy_user_session_path,
        method: :delete,
        class: 'text-gray-400',
        **view_context.data_with_testid('current-user-signout', turbo_method: :delete),
      )
    ])
  end

  def notification_badge
    return '' unless view_context.user_signed_in?

    # data-messages-channel は Stimulus ではなく、チャンネルに関するものです。
    # app/javascript/channels/messages_channel.js
    view_context.content_tag(:span, 'Notifications', class: 'sr-only') +
    view_context.content_tag(:div, '&nbsp;'.html_safe,
      data: { messages_channel: 'notification' },
      class: 'absolute inline-flex items-center justify-center w-4 h-4 text-xs text-white bg-red-500 border-white rounded-full -top-1 -end-1 hidden'
    )
  end
end

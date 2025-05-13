class CurrentUserPresenter
  def initialize(user)
    @user = user
  end

  def meta_tag
    return unless @user
    ActionController::Base.helpers.tag.meta(name: 'current-user-id', content: @user.id)
  end

  def links
    return '' unless @user

    ApplicationController.helpers.safe_join([
      ApplicationController.helpers.link_to(
        @user.username,
        Rails.application.routes.url_helpers.edit_user_registration_path,
        class: 'text-gray-800 dark:text-white',
      ),
      ApplicationController.helpers.link_to(
        'Sign out',
        Rails.application.routes.url_helpers.destroy_user_session_path,
        method: :delete,
        class: 'text-gray-800 dark:text-white',
        data: { turbo_method: :delete },
      )
    ])
  end

  def notification_badge
    return '' unless @user

    # data-messages-channel は Stimulus ではなく、チャンネルに関するものです。
    # app/javascript/channels/messages_channel.js
    <<~HTML.html_safe
      <span class="sr-only">Notifications</span>
      <div data-messages-channel="notification" class="absolute inline-flex items-center justify-center w-4 h-4 text-xs text-white bg-red-500 border-white rounded-full -top-1 -end-1 hidden">
        &nbsp;
      </div>
    HTML
  end

  def logged_in?
    @user.present?
  end
end

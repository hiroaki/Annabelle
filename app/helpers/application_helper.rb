module ApplicationHelper
  def in_configuration_layout?
    user_signed_in? && %w[registrations users two_factor_settings].include?(controller_name)
  end

  def flash_storage
    render 'shared/flash_storage'
  end

  def flash_container
    # flash message display container
    content_tag(:div, '', id: 'flash-message-container')
  end
end

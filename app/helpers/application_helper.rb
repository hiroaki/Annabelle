module ApplicationHelper
  def in_configuration_layout?
    user_signed_in? && %w[registrations users two_factor_settings].include?(controller_name)
  end

  # flash message storage
  def flash_storage
    render 'shared/flash_storage'
  end

  # flash message display container
  def flash_container
    content_tag(:div, '', data: { flash_message_container: true })
  end

  # Flash message templates for JS rendering
  def flash_templates
    templates = [
      {
        id: 'alert',
        text_color: 'text-red-700',
        bg_color: 'bg-red-100'
      },
      {
        id: 'notice',
        text_color: 'text-blue-700',
        bg_color: 'bg-blue-100'
      },
      {
        id: 'warning',
        text_color: 'text-yellow-700',
        bg_color: 'bg-yellow-100'
      }
    ]

    safe_join(
      templates.map do |tpl|
        content_tag(:template, id: "flash-message-template-#{tpl[:id]}") do
          content_tag(:div,
            content_tag(:span, '', class: 'flash-message-text'),
            class: "p-4 mb-4 text-sm rounded-lg #{tpl[:text_color]} #{tpl[:bg_color]}",
            role: 'alert',
            data: { testid: 'flash-message', controller: 'dismissable' }
          )
        end
      end
    )
  end

  # General error messages
  def flash_general_error_messages
    status_codes = %w[
      400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417 418
      421 422 423 424 425 426 428 429 431 451
      500 501 502 503 504 505 506 507 508 510 511
      network
    ]

    content_tag(:ul, id: 'general-error-messages', style: 'display: none;') do
      safe_join(
        status_codes.map do |code|
          content_tag(:li, t("http_status_messages.#{code}"), data: { status: code })
        end
      )
    end
  end

  # General flash-storage using by Turbo Stream
  def flash_global_storage
    content_tag(:div, '', id: 'flash-storage', style: 'display: none;')
  end

  def exported_locale_messages
    keys = %w[
      cable_disconnected
    ]
    content_tag(:ul, id: 'exported-locale-messages', style: 'display: none;') do
      safe_join(
        keys.map do |key|
          content_tag(:li, t("exports.#{key}"), data: { key: key })
        end
      )
    end
  end
end

module ApplicationHelper
  def in_configuration_layout?
    user_signed_in? && %w[registrations users two_factor_settings].include?(controller_name)
  end

  # Override flash_unified (gem) view helper
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

  # 二要素認証を利用する設定であるか否かを返します。
  #
  # 現状の判定ロジックについて:
  # 2FA の有効/無効は、環境変数 ENABLE_2FA の有無のみで判定しています。
  # 実際には config/application.rb で環境変数を元に 2FA の有効化処理が行われ、
  # その結果アプリケーションが2FA有効状態で起動します。
  # ただし、ここではアプリの実際の状態までは参照せず、環境変数のみを見ています。
  # より厳密な判定が必要な場合は、config で判定した結果を Rails.configuration.x などに保存し、
  # それを参照する設計が推奨されます。
  def two_factor_auth_available?
    ENV['ENABLE_2FA'].present?
  end
end

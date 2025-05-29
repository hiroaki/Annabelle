# spec/support/expect_error_message_helper.rb
# フォーム送信時のバリデーションエラー表示を簡潔にテストするためのヘルパーです。
# system spec で利用できます。

module ExpectErrorMessageHelper
  # model: User など必須
  # attribute: :username, :email, etc.
  # error_key: :blank, :invalid_format, :confirmation, etc.
  def expect_error_message(model, attribute, error_key)
    raise ArgumentError, 'model must be specified for expect_error_message' if model.nil?
    if error_key == :confirmation
      # confirmationバリデーションはI18n補間が必要
      label = model.human_attribute_name(:password_confirmation)
      message = I18n.t('errors.messages.confirmation', attribute: model.human_attribute_name(:password))
    else
      label = model.human_attribute_name(attribute)
      message = I18n.t("errors.messages.#{error_key}")
    end
    expect(page).to have_content("#{label} #{message}")
  end
end

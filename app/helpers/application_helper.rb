module ApplicationHelper
  def in_configuration_layout?
    user_signed_in? && %w[registrations users two_factor_settings].include?(controller_name)
  end
end

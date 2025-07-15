module ProxyErrorHelper
  # Helper method to include proxy error handling data attributes
  def proxy_error_handler_data
    {
      controller: "proxy-error-handler",
      proxy_error_handler_locale_value: I18n.locale,
      proxy_error_handler_show_limits_value: ProxyConfiguration.show_limits?,
      proxy_error_handler_request_size_limit_value: ProxyConfiguration.formatted_limit
    }
  end

  # Generate data attributes for specific elements that need proxy error handling
  def proxy_error_data_attributes
    {
      "data-controller" => "proxy-error-handler",
      "data-proxy-error-handler-locale-value" => I18n.locale,
      "data-proxy-error-handler-show-limits-value" => ProxyConfiguration.show_limits?,
      "data-proxy-error-handler-request-size-limit-value" => ProxyConfiguration.formatted_limit
    }
  end
end
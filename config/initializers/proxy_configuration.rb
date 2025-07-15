# Proxy configuration initializer
# Configure proxy settings for request limits and error handling

Rails.application.configure do
  # Proxy settings configuration
  config.proxy_settings = {
    # Maximum request size limit (can be overridden by PROXY_REQUEST_SIZE_LIMIT env var)
    # Accepts string with units (e.g., "100MB", "1GB") or integer in bytes
    request_size_limit: 100.megabytes,
    
    # Whether to show size limits in error messages to users
    # (can be overridden by PROXY_SHOW_LIMITS env var)
    show_limits: true
  }
end
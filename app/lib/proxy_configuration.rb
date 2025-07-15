# Proxy configuration management for request limits and error handling
class ProxyConfiguration
  include Singleton

  # Default values for proxy settings
  DEFAULT_REQUEST_SIZE_LIMIT = 100.megabytes
  DEFAULT_SHOW_LIMITS = true

  def initialize
    @config = load_config
  end

  # Get the maximum request size limit
  def self.request_size_limit
    instance.request_size_limit
  end

  # Whether to show size limits in error messages
  def self.show_limits?
    instance.show_limits?
  end

  # Get formatted limit string for display
  def self.formatted_limit
    instance.formatted_limit
  end

  def request_size_limit
    @config[:request_size_limit] || DEFAULT_REQUEST_SIZE_LIMIT
  end

  def show_limits?
    @config[:show_limits].nil? ? DEFAULT_SHOW_LIMITS : @config[:show_limits]
  end

  def formatted_limit
    limit = request_size_limit
    case limit
    when 0...1.kilobyte
      "#{limit} bytes"
    when 1.kilobyte...1.megabyte
      "#{(limit / 1.kilobyte).round(1)} KB"
    when 1.megabyte...1.gigabyte
      "#{(limit / 1.megabyte).round(1)} MB"
    else
      "#{(limit / 1.gigabyte).round(1)} GB"
    end
  end

  private

  def load_config
    config = {}
    
    # Load from environment variables
    if ENV['PROXY_REQUEST_SIZE_LIMIT'].present?
      config[:request_size_limit] = parse_size(ENV['PROXY_REQUEST_SIZE_LIMIT'])
    end
    
    if ENV['PROXY_SHOW_LIMITS'].present?
      config[:show_limits] = ENV['PROXY_SHOW_LIMITS'].downcase == 'true'
    end

    # Load from Rails configuration if available
    if Rails.application.config.respond_to?(:proxy_settings)
      rails_config = Rails.application.config.proxy_settings
      config[:request_size_limit] ||= rails_config[:request_size_limit] if rails_config[:request_size_limit]
      config[:show_limits] = rails_config[:show_limits] if !config.key?(:show_limits) && rails_config.key?(:show_limits)
    end

    config
  end

  def parse_size(size_string)
    return size_string if size_string.is_a?(Integer)
    
    size_string = size_string.to_s.strip.downcase
    
    case size_string
    when /^(\d+(?:\.\d+)?)\s*g(?:b|iga?byte?s?)?$/i
      ($1.to_f * 1.gigabyte).to_i
    when /^(\d+(?:\.\d+)?)\s*m(?:b|ega?byte?s?)?$/i
      ($1.to_f * 1.megabyte).to_i
    when /^(\d+(?:\.\d+)?)\s*k(?:b|ilo?byte?s?)?$/i
      ($1.to_f * 1.kilobyte).to_i
    when /^(\d+)\s*b(?:ytes?)?$/i
      $1.to_i
    when /^\d+$/
      size_string.to_i
    else
      DEFAULT_REQUEST_SIZE_LIMIT
    end
  end
end
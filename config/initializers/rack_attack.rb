# rack_attack.rb - Demo purposes only: settings are deliberately strict for public access

# Uncomment the following lines to always allow requests from localhost.
# All blocklists and throttles will be skipped for localhost requests.
#Rack::Attack.safelist('allow from localhost') do |req|
#  '127.0.0.1' == req.ip || '::1' == req.ip
#end

rack_attack_config = Module.new do
  module_function

  def env_boolean(name, default)
    value = ENV.key?(name) ? ENV[name] : default
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def env_positive_integer(name, default)
    value = ENV.fetch(name, default.to_s)
    integer = Integer(value, 10)
    integer.positive? ? integer : default
  rescue ArgumentError, TypeError
    default
  end

  def env_probe_path
    %r{\A/\.env(?:\.[^/?#]+)?\z}i
  end

  def throttled_path_exclusions
    ['/up'].freeze
  end

  def ban_cache_key(ip)
    "rack:attack:ban:#{ip}"
  end

  def settings
    {
      enabled: env_boolean('ENABLED_RACK_ATTACK', '1'),
      get_throttle_name: 'req/ip:get',
      write_throttle_name: 'req/ip:write',
      get_throttle_limit: env_positive_integer('RACK_ATTACK_GET_THROTTLE_LIMIT', 300),
      write_throttle_limit: env_positive_integer('RACK_ATTACK_WRITE_THROTTLE_LIMIT', 60),
      throttle_period: env_positive_integer('RACK_ATTACK_THROTTLE_PERIOD_SECONDS', 60).seconds,
      ban_duration: env_positive_integer('RACK_ATTACK_BAN_DURATION_SECONDS', 600).seconds,
      env_probe_path: env_probe_path,
      throttled_path_exclusions: throttled_path_exclusions
    }
  end
end

rack_attack_settings = rack_attack_config.settings

Rack::Attack.enabled = rack_attack_settings[:enabled]
Rack::Attack.cache.store = Rails.cache

if rack_attack_settings[:enabled]
  # Block IPs that request .env or similar sensitive files (immediate ban and cache)
  Rack::Attack.blocklist('block env file scanners') do |req|
    if req.path.match?(rack_attack_settings[:env_probe_path])
      Rack::Attack.cache.store.write(
        rack_attack_config.ban_cache_key(req.ip),
        '1',
        expires_in: rack_attack_settings[:ban_duration]
      )
      true
    else
      false
    end
  end

  Rack::Attack.throttle(
    rack_attack_settings[:get_throttle_name],
    limit: rack_attack_settings[:get_throttle_limit],
    period: rack_attack_settings[:throttle_period]
  ) do |req|
    req.ip if (req.get? || req.head?) && !rack_attack_settings[:throttled_path_exclusions].include?(req.path)
  end

  Rack::Attack.throttle(
    rack_attack_settings[:write_throttle_name],
    limit: rack_attack_settings[:write_throttle_limit],
    period: rack_attack_settings[:throttle_period]
  ) do |req|
    req.ip unless req.get? || req.head?
  end

  Rack::Attack.blocklist('ban abusive IPs') do |req|
    Rack::Attack.cache.store.read(rack_attack_config.ban_cache_key(req.ip)) == '1'
  end

  Rack::Attack.throttled_responder = lambda do |_request|
    headers = {
      'Content-Type' => 'application/json; charset=utf-8',
      'Retry-After' => rack_attack_settings[:throttle_period].to_i.to_s
    }

    body = {
      error: 'throttled',
      message: 'Rate limit exceeded, retry after some time'
    }.to_json

    [429, headers, [body]]
  end

  Rack::Attack.blocklisted_responder = lambda do |_request|
    headers = {
      'Content-Type' => 'application/json; charset=utf-8',
      'Retry-After' => rack_attack_settings[:ban_duration].to_i.to_s
    }

    body = {
      error: 'forbidden',
      message: 'Access denied due to suspicious activity'
    }.to_json

    [403, headers, [body]]
  end

end

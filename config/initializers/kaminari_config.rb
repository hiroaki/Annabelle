# frozen_string_literal: true

dpp = ENV['KAMINARI_DEFAULT_PER_PAGE'].to_i
dpp = dpp < 1 ? 10 : dpp

Kaminari.configure do |config|
  config.default_per_page = dpp
  # config.max_per_page = nil
  config.window = 3 # default = 4
  # config.outer_window = 0
  # config.left = 0
  # config.right = 0
  # config.page_method_name = :page
  # config.param_name = :page
  # config.max_pages = nil
  # config.params_on_first_page = false
end

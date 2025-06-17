require "capybara/cuprite"
require 'capybara/dsl'
require_relative 'config/environment'

options = {
  url: 'http://chrome:3333',
  browser_options: { 'no-sandbox': nil },
  base_url: "http://web:3000"
}

Capybara.register_driver(:cuprite_custom) do |app|
  Capybara::Cuprite::Driver.new(app,options)
end

Capybara.javascript_driver = :cuprite_custom
Capybara.server_host = "0.0.0.0"
Capybara.server_port = "3000"
Capybara.app_host = "http://web:3000"

puts "Capybara.app_host: #{Capybara.app_host}"

# Railsアプリケーションを取得
app = Rails.application

session = Capybara::Session.new(:cuprite_custom, app)
driver = session.driver
browser = driver.browser
page = browser.page
browser.visit "/"
puts page.title


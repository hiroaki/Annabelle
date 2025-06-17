require 'ferrum'

options = {
    url: 'http://chrome:3333',
    browser_options: { 'no-sandbox': nil }
}
browser = Ferrum::Browser.new(options)
browser.go_to("https://google.com")
puts browser.current_title
browser.quit


require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  served_by host: "localhost", port: nil

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1280, 900 ] do |options|
    options.binary = ENV["CHROME_BIN"] if ENV["CHROME_BIN"].present?
    options.add_argument("--no-sandbox") if Process.euid.zero?
    options.add_argument("--disable-dev-shm-usage")
  end
end

# frozen_string_literal: true

require "cryptohopper"
require "webmock/rspec"

WebMock.disable_net_connect!(allow_localhost: false)

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

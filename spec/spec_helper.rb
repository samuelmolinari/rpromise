require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'rpromise'

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.syntax = :should
  end
end

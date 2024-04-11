# frozen_string_literal: true

ENV['APP_ENV'] ||= 'test'

require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
end

require 'rspec'
require_relative '../lib/vending_machine'

RSpec.configure do |config|
  config.expect_with(:rspec) do |c|
    c.syntax = :expect
  end

  config.disable_monkey_patching!
end

# frozen_string_literal: true

require "rspec"
require_relative "../lib/vending_machine"

RSpec.configure do |config|
  config.expect_with(:rspec) do |c|
    c.syntax = :expect
  end

  config.disable_monkey_patching!
end

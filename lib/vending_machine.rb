# frozen_string_literal: true

require 'bundler/setup'

require_relative 'vending_machine/console'

ENV['APP_ENV'] ||= 'development'
Bundler.require(:default, ENV.fetch('APP_ENV', nil))

module VendingMachine
end

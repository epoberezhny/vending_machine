# frozen_string_literal: true

module VendingMachine
  class CashRegister
    NotEnoughChangeError = Class.new(StandardError)

    AVAILABLE_COINS = [5.0, 3.0, 2.0, 1.0, 0.5, 0.25].freeze

    def initialize
      @coins = Hash.new(0)
    end

    def add_coin(coin:, amount:)
      raise ArgumentError unless AVAILABLE_COINS.include?(coin)
      raise ArgumentError if !amount.is_a?(Integer) || amount.negative?

      coins.merge!(coin => amount) { |_key, old, new| old + new }
      nil
    end

    def update_coins(inserted_coins:, change:)
      coins.merge!(inserted_coins) { |_coin, old_a, new_a| old_a + new_a }
      coins.merge!(change) { |_coin, old_a, new_a| old_a - new_a }

      raise ArgumentError if coins.values.any?(&:negative?)

      nil
    end

    def available_coins
      coins.dup
    end

    def calculate_change(change_sum:, inserted_coins:)
      all_coins = coins.merge(inserted_coins) { |_coin, old_a, new_a| old_a + new_a }

      AVAILABLE_COINS.size.downto(1) do |length|
        current_available_coins = AVAILABLE_COINS.last(length)
        change = change_from_available_coins(change_sum, all_coins, current_available_coins)
        return change unless change.nil?
      end

      raise NotEnoughChangeError
    end

    private

    attr_reader :coins

    def change_from_available_coins(change_sum, all_coins, available_coins)
      available_coins.each_with_object(Hash.new(0)) do |coin, change|
        all_coins[coin].times do
          break if (change_sum - coin).negative?

          change[coin] += 1
          change_sum -= coin
        end
      end.tap do
        return if change_sum.positive?
      end
    end
  end
end

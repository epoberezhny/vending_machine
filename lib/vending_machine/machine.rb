# frozen_string_literal: true

require_relative 'stock'
require_relative 'cash_register'

module VendingMachine
  class Machine
    extend Forwardable

    attr_reader :current_product

    def_delegators :stock, :add_product, :reduce_quantity, :available_products,
                   :available_products_empty?
    def_delegators :cash_register, :add_coin

    def initialize(stock: Stock.new, cash_register: CashRegister.new)
      @stock = stock
      @cash_register = cash_register
      reset!
    end

    def select_current_product(product:)
      raise ArgumentError unless available_products.any?(&product.method(:equal?))

      @current_product = product
    end

    def insert_coin(coin:)
      raise ArgumentError unless CashRegister::AVAILABLE_COINS.include?(coin)

      inserted_coins[coin] += 1
    end

    def enough_coins?
      return false if current_product.nil? || inserted_coins.empty?

      current_product.price <= inserted_sum
    end

    def calculate_change
      return {} if current_product.nil? || inserted_coins.empty?

      cash_register.calculate_change(
        change_sum: inserted_sum - current_product.price,
        inserted_coins:
      )
    end

    def confirm_purchase!
      return false if current_product.nil? || inserted_coins.empty?

      calculate_change.tap do |change|
        stock.decrement_quantity(product: current_product, by: 1)
        cash_register.update_coins(inserted_coins:, change:)
      end
    ensure
      reset!
    end

    def inserted_sum
      inserted_coins.sum { |coin, amount| coin * amount }
    end

    private

    attr_reader :stock, :cash_register, :inserted_coins

    def reset!
      @current_product = nil
      @inserted_coins = Hash.new(0)
    end
  end
end

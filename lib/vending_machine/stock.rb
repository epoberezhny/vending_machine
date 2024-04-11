# frozen_string_literal: true

require_relative 'product'

module VendingMachine
  class Stock
    def initialize
      @products = []
    end

    def add_product(name:, quantity:, price:) # rubocop:disable Metrics/AbcSize
      raise ArgumentError unless name.is_a?(String)
      raise ArgumentError if !quantity.is_a?(Integer) || quantity.negative?
      raise ArgumentError if !price.is_a?(Float) || price.negative?

      if (existing_product = find_product(name))
        return existing_product.increment!(by: quantity)
      end

      products.push(Product.new(name:, quantity:, price:)).last
    end

    def decrement_quantity(product:, by:)
      raise ArgumentError unless available_products.any?(&product.method(:equal?))

      product.decrement!(by:)
    end

    def all_products
      products.dup
    end

    def available_products
      products.select(&:available?)
    end

    def available_products_empty?
      available_products.empty?
    end

    private

    attr_reader :products

    def find_product(name)
      products.find { |product| product.name == name }
    end
  end
end

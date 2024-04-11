# frozen_string_literal: true

module VendingMachine
  Product = Struct.new(:name, :quantity, :price, keyword_init: true) do
    def available?
      quantity.positive?
    end

    def increment!(by:)
      raise ArgumentError unless by.is_a?(Integer)

      self.quantity = [0, quantity + by].max
      self
    end

    def decrement!(by:)
      raise ArgumentError unless by.is_a?(Integer)

      self.quantity = [0, quantity - by].max
      self
    end

    def to_s(with_price: false, with_quantity: false)
      details = [
        ("Price: #{price}" if with_price),
        ("Quantity: #{quantity}" if with_quantity)
      ].compact
      return name if details.empty?

      "#{name} (#{details.join(', ')})"
    end

    private :name=, :quantity=, :price=
  end
end

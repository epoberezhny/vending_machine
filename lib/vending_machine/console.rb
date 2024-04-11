# frozen_string_literal: true

require 'highline'
require_relative 'machine'

module VendingMachine
  class Console
    def initialize(io: HighLine.new, machine: Machine.new)
      @io = io
      @machine = machine
    end

    def run
      show_welcome_message
      exit_on_empty_stock if @machine.available_products_empty?

      loop do
        select_product while @machine.current_product.nil?
        collect_coin until @machine.enough_coins?
        confirm_purchase
      end
    rescue Interrupt
      show_bye_message
    end

    private

    def exit_on_empty_stock
      @io.say('There are no available products. Please come back later.')
      exit(0)
    end

    def show_welcome_message
      @io.say("Welcome! Press Ctrl+C to exit.\n\n")
    end

    def select_product
      product = choose_product
      confirm_product(product)
    end

    def choose_product
      @io.choose do |menu|
        menu.prompt = 'Please choose a product: '

        @machine.available_products.each do |product|
          text = product.to_s(with_price: true, with_quantity: true)
          menu.choice(product.name, nil, text) { product }
        end
      end
    end

    def confirm_product(product)
      res =
        @io.agree("\nYou have selected: #{product.to_s(with_price: true)}. Proceed to checkout?")
      @machine.select_current_product(product:) if res
    end

    def collect_coin
      coin =
        @io.ask(
          "\nInserted amount: #{@machine.inserted_sum}. " \
          "Please insert a coin (available coins: #{CashRegister::AVAILABLE_COINS}): ",
          Float
        ) do |q|
          q.in = CashRegister::AVAILABLE_COINS
        end

      @machine.insert_coin(coin:)
    end

    def confirm_purchase
      change = @machine.confirm_purchase!

      change_str = change.map { |coin, amount| "#{coin} * #{amount}" }.join(', ')
      @io.say("\nPurchase is successful. Your change: #{change_str}\n\n")
    rescue CashRegister::NotEnoughChangeError
      @io.say("\nThere is not enough change. Please take your money back.\n\n")
    end

    def show_bye_message
      @io.say("\nGood bye!")
    end
  end
end

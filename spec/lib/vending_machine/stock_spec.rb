# frozen_string_literal: true

RSpec.describe VendingMachine::Stock do
  subject(:stock) { described_class.new }

  describe '#add_product' do
    subject(:add_product) { -> { stock.add_product(name:, quantity:, price:) } }

    let(:name) { 'name' }
    let(:quantity) { 1 }
    let(:price) { 1.0 }

    context 'with invalid args' do
      context 'when name is invalid' do
        let(:name) { 1 }

        it 'raises ArgumentError' do
          expect { add_product.call }.to raise_error(ArgumentError)
        end
      end

      context 'when quantity is invalid' do
        context 'when wrong type' do
          let(:quantity) { 1.0 }

          it 'raises ArgumentError' do
            expect { add_product.call }.to raise_error(ArgumentError)
          end
        end

        context 'when negative value' do
          let(:quantity) { -1 }

          it 'raises ArgumentError' do
            expect { add_product.call }.to raise_error(ArgumentError)
          end
        end
      end

      context 'when price is invalid' do
        context 'when wrong type' do
          let(:price) { 1 }

          it 'raises ArgumentError' do
            expect { add_product.call }.to raise_error(ArgumentError)
          end
        end

        context 'when negative value' do
          let(:price) { -1.0 }

          it 'raises ArgumentError' do
            expect { add_product.call }.to raise_error(ArgumentError)
          end
        end
      end
    end

    context 'with valid args' do
      it 'adds a new product' do
        expect { add_product.call }.to change(stock, :all_products).from([]).to([
          VendingMachine::Product.new(name:, quantity:, price:)
        ])
      end

      it 'updates quantity on double addition' do
        expect { 2.times { add_product.call } }.to change(stock, :all_products).from([]).to([
          VendingMachine::Product.new(name:, quantity: quantity * 2, price:)
        ])
      end

      it 'returns added product' do
        expect(add_product.call).to be_instance_of(VendingMachine::Product)
        # check double addition too
        expect(add_product.call).to be_instance_of(VendingMachine::Product)
      end
    end
  end

  describe '#decrement_quantity' do
    subject(:decrement_quantity) { stock.decrement_quantity(product:, by:) }

    let!(:product) { stock.add_product(name: '1', quantity: 1, price: 1.0) }

    let(:by) { 1 }

    context 'with invalid args' do
      context 'when product has never been in stock' do
        let!(:product) { VendingMachine::Product.new } # rubocop:disable RSpec/LetSetup

        it 'raises ArgumentError' do
          expect { decrement_quantity }.to raise_error(ArgumentError)
        end
      end

      context 'when is out of stock' do
        let!(:product) { stock.add_product(name: '1', quantity: 0, price: 1.0) } # rubocop:disable RSpec/LetSetup

        it 'raises ArgumentError' do
          expect { decrement_quantity }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with valid args' do
      it 'decrements product quantity' do
        expect { decrement_quantity }.to change(product, :quantity).by(-1)
      end
    end
  end

  describe '#all_products' do
    before do
      stock.add_product(name: '1', quantity: 0, price: 1.0)
      stock.add_product(name: '2', quantity: 1, price: 2.0)
    end

    it 'returns all added products' do
      expect(stock.all_products).to eq([
        VendingMachine::Product.new(name: '1', quantity: 0, price: 1.0),
        VendingMachine::Product.new(name: '2', quantity: 1, price: 2.0)
      ])
    end

    it 'returns different object on each call' do
      expect(stock.all_products).not_to equal(stock.all_products)
    end
  end

  describe '#available_products' do
    before do
      stock.add_product(name: '1', quantity: 0, price: 1.0)
      stock.add_product(name: '2', quantity: 1, price: 2.0)
    end

    it 'returns all added products' do
      expect(stock.available_products).to eq([
        VendingMachine::Product.new(name: '2', quantity: 1, price: 2.0)
      ])
    end
  end

  describe '#available_products_empty?' do
    subject { stock.available_products_empty? }

    context 'when empty' do
      it { is_expected.to be(true) }
    end

    context 'when non empty' do
      before do
        stock.add_product(name: '1', quantity: 0, price: 1.0)
        stock.add_product(name: '2', quantity: 1, price: 2.0)
      end

      it { is_expected.to be(false) }
    end
  end
end

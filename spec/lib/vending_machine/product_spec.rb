# frozen_string_literal: true

RSpec.describe VendingMachine::Product do
  subject(:product) { described_class.new(name:, quantity:, price:) }

  let(:name) { 'name' }
  let(:quantity) { 0 }
  let(:price) { 1.0 }

  describe '#available?' do
    context 'when unavailable' do
      it { is_expected.not_to be_available }
    end

    context 'when available' do
      let(:quantity) { 1 }

      it { is_expected.to be_available }
    end
  end

  describe '#increment!' do
    context 'with invalid by' do
      it 'raises ArgumentError' do
        expect { product.increment!(by: '') }.to raise_error(ArgumentError)
      end
    end

    context 'with valid by' do
      let(:by) { 2 }

      it 'increments quantity' do
        expect { product.increment!(by:) }.to change(product, :quantity).by(by)
      end

      it 'returns self' do
        expect(product.increment!(by:)).to eq(product)
      end

      context 'with nagative by' do
        let(:by) { -2 }

        context 'when abs(by) > quantity' do
          let(:quantity) { 1 }

          it 'sets quantity to 0' do
            expect { product.increment!(by:) }.to change(product, :quantity).to(0)
          end
        end

        context 'when abs(by) < quantity' do
          let(:quantity) { 3 }

          it 'decrements quantity' do
            expect { product.increment!(by:) }.to change(product, :quantity).by(by)
          end
        end
      end
    end
  end

  describe '#decrement!' do
    context 'with invalid by' do
      it 'raises ArgumentError' do
        expect { product.decrement!(by: '') }.to raise_error(ArgumentError)
      end
    end

    context 'with valid by' do
      let(:by) { -2 }
      let(:quantity) { 3 }

      it 'increments quantity' do
        expect { product.decrement!(by:) }.to change(product, :quantity).by(-by)
      end

      it 'returns self' do
        expect(product.increment!(by:)).to eq(product)
      end

      context 'with positive by' do
        let(:by) { 2 }

        context 'when by > quantity' do
          let(:quantity) { 1 }

          it 'sets quantity to 0' do
            expect { product.decrement!(by:) }.to change(product, :quantity).to(0)
          end
        end

        context 'when by < quantity' do
          let(:quantity) { 3 }

          it 'decrements quantity' do
            expect { product.decrement!(by:) }.to change(product, :quantity).by(-by)
          end
        end
      end
    end
  end

  describe '#to_s' do
    subject { product.to_s(with_price:, with_quantity:) }

    let(:with_price) { false }
    let(:with_quantity) { false }

    it { is_expected.to eq(name) }

    context 'when with_price = true' do
      let(:with_price) { true }

      it { is_expected.to eq('name (Price: 1.0)') }
    end

    context 'when with_quantity = true' do
      let(:with_quantity) { true }

      it { is_expected.to eq('name (Quantity: 0)') }
    end

    context 'when with_price = true and with_quantity = true' do
      let(:with_price) { true }
      let(:with_quantity) { true }

      it { is_expected.to eq('name (Price: 1.0, Quantity: 0)') }
    end
  end
end

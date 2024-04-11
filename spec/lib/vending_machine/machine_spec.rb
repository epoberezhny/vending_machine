# frozen_string_literal: true

RSpec.describe VendingMachine::Machine do
  subject(:machine) { described_class.new(stock:, cash_register:) }

  let(:stock) { instance_double(VendingMachine::Stock) }
  let(:cash_register) { instance_double(VendingMachine::CashRegister) }

  describe '#select_current_product' do
    subject(:select_current_product) { machine.select_current_product(product:) }

    context 'with invalid args' do
      before { allow(stock).to receive(:available_products).and_return([]) }

      context 'when product is not available' do
        let(:product) { VendingMachine::Product.new(name: '', quantity: 1, price: 1.0) }

        it 'raises ArgumentError' do
          expect { select_current_product }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with valid args' do
      before { allow(stock).to receive(:available_products).and_return([product]) }

      let(:product) { VendingMachine::Product.new(name: '', quantity: 1, price: 1.0) }

      it 'sets current product' do
        expect { select_current_product }.to change(machine, :current_product).from(nil).to(product)
      end
    end
  end

  describe '#insert_coin' do
    subject(:insert_coin) { -> { machine.insert_coin(coin:) } }

    context 'with invalid args' do
      context 'when coin is not available' do
        let(:coin) { 100 }

        it 'raises ArgumentError' do
          expect { insert_coin.call }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with valid args' do
      let(:coin) { 0.25 }

      it 'inserts coin' do
        expect { insert_coin.call }.to change(machine, :inserted_sum).from(0).to(coin)
      end

      it 'inserts coins' do
        expect { 2.times { insert_coin.call } }.to change(machine, :inserted_sum)
          .from(0).to(coin * 2)
      end
    end
  end

  describe '#enough_coins?' do
    subject(:enough_coins?) { machine.enough_coins? }

    let(:product) { VendingMachine::Product.new(name: '', quantity: 1, price: 1.0) }

    before { allow(stock).to receive(:available_products).and_return([product]) }

    context 'when current product is not selected' do
      it { is_expected.to be(false) }
    end

    context 'when there is no inserted coins' do
      before { machine.select_current_product(product:) }

      it { is_expected.to be(false) }
    end

    context 'when there is not enough coins' do
      before do
        machine.select_current_product(product:)
        2.times { machine.insert_coin(coin: 0.25) }
      end

      it { is_expected.to be(false) }
    end

    context 'when there is enough coins' do
      before do
        machine.select_current_product(product:)
        2.times { machine.insert_coin(coin: 0.5) }
      end

      it { is_expected.to be(true) }
    end
  end

  describe '#calculate_change' do
    subject(:calculate_change) { machine.calculate_change }

    let(:product) { VendingMachine::Product.new(name: '', quantity: 1, price: 1.0) }

    before { allow(stock).to receive(:available_products).and_return([product]) }

    context 'when current product is not selected' do
      it { is_expected.to eq({}) }
    end

    context 'when there is no inserted coins' do
      before { machine.select_current_product(product:) }

      it { is_expected.to eq({}) }
    end

    context 'when current product is selected and coins are inserted' do
      before do
        allow(cash_register).to receive(:calculate_change).and_return(:change)

        machine.select_current_product(product:)
        machine.insert_coin(coin: 3.0)
      end

      it 'calculates change' do
        expect(calculate_change).to eq(:change)
        expect(cash_register).to have_received(:calculate_change).with(
          change_sum: 2.0,
          inserted_coins: { 3.0 => 1 }
        )
      end
    end
  end

  describe '#confirm_purchase!' do
    subject(:confirm_purchase!) { machine.confirm_purchase! }

    let(:product) { VendingMachine::Product.new(name: '', quantity: 1, price: 1.0) }

    before { allow(stock).to receive(:available_products).and_return([product]) }

    context 'when current product is not selected' do
      it { is_expected.to be(false) }
    end

    context 'when there is no inserted coins' do
      before { machine.select_current_product(product:) }

      it { is_expected.to be(false) }
    end

    # rubocop:disable RSpec/SubjectStub
    context 'when current product is selected and coins are inserted' do
      before do
        allow(stock).to receive(:decrement_quantity).and_return(product)
        allow(cash_register).to receive(:update_coins).and_return(nil)

        machine.select_current_product(product:)
        machine.insert_coin(coin: 3.0)
      end

      context 'when there is enough change' do
        before { allow(machine).to receive(:calculate_change).and_return(:change) }

        it 'confirms purchase and returns change' do
          expect(confirm_purchase!).to eq(:change)

          expect(stock).to have_received(:decrement_quantity).with(product:, by: 1)
          expect(machine).to have_received(:calculate_change)
          expect(cash_register).to have_received(:update_coins).with(
            inserted_coins: { 3.0 => 1 },
            change: :change
          )
        end
      end

      context 'when there is not enough change' do
        before do
          allow(machine).to receive(:calculate_change)
            .and_raise(VendingMachine::CashRegister::NotEnoughChangeError)
        end

        it 'confirms purchase and returns change' do
          expect { confirm_purchase! }.to raise_error(
            VendingMachine::CashRegister::NotEnoughChangeError
          )

          expect(stock).not_to have_received(:decrement_quantity)
          expect(cash_register).not_to have_received(:update_coins)
        end
      end
    end
    # rubocop:enable RSpec/SubjectStub
  end

  describe '#inserted_sum' do
    subject(:inserted_sum) { machine.inserted_sum }

    context 'without inserted coins' do
      it { is_expected.to eq(0) }
    end

    context 'with inserted coins' do
      before do
        2.times { machine.insert_coin(coin: 0.25) }
        machine.insert_coin(coin: 1.0)
      end

      it { is_expected.to eq(1.5) }
    end
  end
end

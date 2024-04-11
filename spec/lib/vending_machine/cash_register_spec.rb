# frozen_string_literal: true

RSpec.describe VendingMachine::CashRegister do
  subject(:cash_register) { described_class.new }

  describe '#add_coin' do
    subject(:add_coin) { -> { cash_register.add_coin(coin:, amount:) } }

    let(:coin) { 0.25 }
    let(:amount) { 1 }

    context 'with invalid args' do
      context 'when coin is invalid' do
        let(:coin) { 100 }

        it 'raises ArgumentError' do
          expect { add_coin.call }.to raise_error(ArgumentError)
        end
      end

      context 'when amount is invalid' do
        context 'when wrong type' do
          let(:amount) { 1.0 }

          it 'raises ArgumentError' do
            expect { add_coin.call }.to raise_error(ArgumentError)
          end
        end

        context 'when negative value' do
          let(:amount) { -1 }

          it 'raises ArgumentError' do
            expect { add_coin.call }.to raise_error(ArgumentError)
          end
        end
      end
    end

    context 'with valid args' do
      it 'adds a new coin' do
        expect { add_coin.call }.to change(cash_register, :available_coins)
          .from({}).to(coin => amount)
      end

      it 'updates amoun on double addition' do
        expect { 2.times { add_coin.call } }.to change(cash_register, :available_coins)
          .from({}).to(coin => amount * 2)
      end

      it 'returns nil' do
        expect(add_coin.call).to be_nil
        expect(add_coin.call).to be_nil # check double addition too
      end
    end
  end

  describe '#update_coins' do
    subject(:update_coins) { cash_register.update_coins(inserted_coins:, change: coins_change) }

    before do
      cash_register.add_coin(coin: 0.25, amount: 0)
      cash_register.add_coin(coin: 5.0, amount: 1)
    end

    context 'with invalid args' do
      let(:inserted_coins) { {} }
      let(:coins_change) { { 0.25 => 1 } }

      it 'updates coins' do
        expect { update_coins }.to raise_error(ArgumentError)
      end
    end

    context 'with valid args' do
      context 'with non empty args' do
        let(:inserted_coins) { { 0.25 => 2, 0.5 => 2, 1.0 => 1 } }
        let(:coins_change) { { 0.25 => 1, 0.5 => 1, 5.0 => 1 } }

        it 'updates coins' do
          expect { update_coins }.to change(cash_register, :available_coins)
            .from(0.25 => 0, 5.0 => 1).to(0.25 => 1, 0.5 => 1, 1.0 => 1, 5.0 => 0)
        end

        it 'returns nil' do
          expect(update_coins).to be_nil
        end
      end

      context 'with empty args' do
        let(:inserted_coins) { {} }
        let(:coins_change) { {} }

        it 'does not update coins' do
          expect { update_coins }.not_to change(cash_register, :available_coins)
        end

        it 'returns nil' do
          expect(update_coins).to be_nil
        end
      end
    end
  end

  describe '#available_coins' do
    before do
      cash_register.add_coin(coin: 0.25, amount: 0)
      cash_register.add_coin(coin: 5.0, amount: 1)
    end

    it 'returns all added coins' do
      expect(cash_register.available_coins).to eq(0.25 => 0, 5.0 => 1)
    end

    it 'returns different object on each call' do
      expect(cash_register.available_coins).not_to equal(cash_register.available_coins)
    end
  end

  describe '#calculate_change' do
    subject(:calculate_change) { cash_register.calculate_change(change_sum:, inserted_coins:) }

    before do
      cash_register.add_coin(coin: 0.25, amount: 3)
      cash_register.add_coin(coin: 2.0, amount: 10)
      cash_register.add_coin(coin: 3.0, amount: 1)
    end

    context 'when there is not enough change' do
      let(:change_sum) { 1.0 }

      context 'without inserted_coins' do
        let(:inserted_coins) { {} }

        it 'raises NotEnoughChangeError' do
          expect { calculate_change }.to raise_error(
            VendingMachine::CashRegister::NotEnoughChangeError
          )
        end
      end

      context 'with inserted_coins' do
        let(:inserted_coins) { { 5 => 1 } }

        it 'raises NotEnoughChangeError' do
          expect { calculate_change }.to raise_error(
            VendingMachine::CashRegister::NotEnoughChangeError
          )
        end
      end
    end

    context 'when there is enough change' do
      context 'with change_sum = 0' do
        let(:change_sum) { 0.0 }
        let(:inserted_coins) { { 5.0 => 1 } }

        it 'returns change' do
          expect(calculate_change).to eq({})
        end

        context 'without inserted_coins' do
          let(:inserted_coins) { {} }

          it 'returns change' do
            expect(calculate_change).to eq({})
          end
        end
      end

      context 'with change_sum > 0' do
        context 'when it is possible to return change with the biggest available coin' do
          let(:change_sum) { 3.75 }
          let(:inserted_coins) { { 0.5 => 1, 3.0 => 1, 5.0 => 1 } }

          it 'returns change' do
            expect(calculate_change).to eq(3.0 => 1, 0.5 => 1, 0.25 => 1)
          end
        end

        context 'when it is not possible to return change with the biggest available coin' do
          let(:change_sum) { 4.0 }
          let(:inserted_coins) { { 3 => 1, 5 => 1 } }

          it 'returns change' do
            expect(calculate_change).to eq(2.0 => 2)
          end
        end
      end
    end
  end
end

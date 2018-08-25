require_relative '../../../app/api'
require 'rack/test'

module ExpenseTracker
  RSpec.describe API do
    include Rack::Test::Methods

    def app
      API.new(ledger: ledger)
    end

    let(:ledger) { instance_double('ExpenseTracker::Ledger') }

    def parsed
      JSON.parse(last_response.body)
    end

    describe 'POST /expenses' do

      context 'when the expense is successfully recorded' do
        let(:expense) { { 'some' => 'data' } }

        before do
          allow(ledger).to receive(:record)
          .with(expense)
          .and_return(RecordResult.new(true, 417, nil))
        end

        it 'returns the expense id' do
          post '/expenses', JSON.generate(expense)

          expect(parsed).to include('expense_id' => 417)
        end

        it 'responds with a 200 (OK)' do
          post 'expenses', JSON.generate(expense)
          expect(last_response.status).to eq(200)
        end
      end

      context 'when the expense fails validation' do
        let(:expense) { { 'some' => 'data' } }

        before do
          allow(ledger).to receive(:record)
          .with(expense)
          .and_return(RecordResult.new(false, 417, 'Expenses incomplete'))
        end

        it 'returns with an error message' do
          post '/expenses', JSON.generate(expense)

          expect(parsed).to include('error' => 'Expenses incomplete')
        end

        it 'responds with a 422 (Unprocessable entity)' do
          post '/expenses', JSON.generate(expense)
          expect(last_response.status).to eq (422)
        end
      end
    end   

    describe 'GET /expenses/:date' do
      context 'when expenses exist on a given date' do
        let(:date) { '2017-06-10' }
        before do
          coffee = {
            'payee' => 'Starbucks',
            'amount' => 5.75,
            'date' => '2017-06-10'
          }

          zoo = {
            'payee' => 'Zoo',
            'amount' => 15.25,
            'date' => '2017-06-10'
          }
          @expenses_on_test_day = [coffee, zoo]

          allow(ledger).to receive(:expenses_on)
          .with(date)
          .and_return(@expenses_on_test_day)
        end

        it 'returns the expense records as JSON' do
          get '/expenses/2017-06-10'
          expect(parsed).to include('expenses' => @expenses_on_test_day)
        end

        it 'responds with a 200 (OK)' do
          get '/expenses/2017-06-10'
          expect(last_response.status).to eq(200)
        end
      end

      context 'when there are no expenses on the given date' do
        let(:date) { '2017-06-11' }
        before do
          allow(ledger).to receive(:expenses_on)
          .with(date)
          .and_return([])
        end

        it 'returns an empty array as JSON' do
          get '/expenses/2017-06-11'
          expect(parsed).to include('expenses' => [])
        end

        it 'responds with a 200 (OK)' do
          get '/expenses/2017-06-11'
          expect(last_response.status).to eq(200)
        end
      end
    end
  end
end
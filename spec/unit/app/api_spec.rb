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
          header 'Content-Type', 'application/json'
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
          header 'Content-Type', 'application/json'
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

      context 'when the expense is an unsupported format' do
        let(:expense) { { 'some' => 'data' } }

        before do
          allow(ledger).to receive(:record)
          .with(expense)
          .and_return(RecordResult.new(true, 417, nil))
          header 'Content-Type', 'unknown'
        end

        it 'returns with an error message' do
          post '/expenses', JSON.generate(expense)

          expect(parsed).to include('error' => 'Unsupported format')
        end

        it 'responds with a 422 (Unprocessable entity)' do
          post '/expenses', JSON.generate(expense)
          expect(last_response.status).to eq (422)
        end
      end

      context 'when the content does not match the specified format' do
        let(:expense) { { 'some' => 'data' } }

        before do
          allow(ledger).to receive(:record)
          .with(expense)
          .and_return(RecordResult.new(true, 417, nil))
        end

        it 'responds with a 415 (Unsupported Media Type)' do
          header 'Content-Type', 'application/json'
          post '/expenses', Ox.dump(expense)
          expect(last_response.status).to eq (415)

          header 'Content-Type', 'text/xml'
          post '/expenses', JSON.generate(expense)
          expect(last_response.status).to eq (415)
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

          header 'Accept', 'application/json'
        end

        it 'returns the expense records as JSON' do
          get '/expenses/2017-06-10'
          expect(parsed).to eq(@expenses_on_test_day)
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

          header 'Accept', 'application/json'
        end

        it 'returns an empty array as JSON' do
          get '/expenses/2017-06-11'
          expect(parsed).to eq([])
        end

        it 'responds with a 200 (OK)' do
          get '/expenses/2017-06-11'
          expect(last_response.status).to eq(200)
        end
      end

      context 'when it requests for an unsupported format' do
        let(:date) { '2017-06-11' }
        before do
          allow(ledger).to receive(:expenses_on)
          .with(date)
          .and_return([])

          header 'Accept', 'text/unknown'
        end

        it 'responds with a 406 (Not Acceptable)' do
          get '/expenses/2017-06-11'
          expect(last_response.status).to eq(406)
        end
      end
    end
  end
end
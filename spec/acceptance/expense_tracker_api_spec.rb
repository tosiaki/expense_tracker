require 'rack/test'
require 'json'
require 'ox'
require_relative '../../app/api'
require_relative '../../app/adapters'

module ExpenseTracker
  RSpec.describe 'Expense Tracker API', :db do
    include Rack::Test::Methods

    def app
      ExpenseTracker::API.new
    end

    def post_expense(expense,format=:json)
      case format
      when :json
        data_handler = JSON
        type = 'application/json'
      when :xml
        data_handler = XMLAdapter.new
        type = 'text/xml'
      end

      header 'Content-Type', type
      post '/expenses', data_handler.generate(expense) # JSON.generate(expense)
      expect(last_response.status).to eq(200)

      parsed = data_handler.parse(last_response.body) # JSON.parse(last_response.body)
      expect(parsed).to include('expense_id' => a_kind_of(Integer))
      expense.merge('id' => parsed['expense_id'])
    end

    it 'records submitted expenses' do
      coffee = post_expense(
        'payee' => 'Starbucks',
        'amount' => 5.75,
        'date' => '2017-06-10'
      )

      zoo = post_expense(
        'payee' => 'Zoo',
        'amount' => 15.25,
        'date' => '2017-06-10'
      )

      groceries = post_expense(
        'payee' => 'Whole Foods',
        'amount' => 95.20,
        'date' => '2017-06-11'
      )

      tea = post_expense({
        'payee' => 'Whole Foods',
        'amount' => 3.10,
        'date' => '2017-06-12'
      }, :xml)

      get '/expenses/2017-06-10'
      expect(last_response.status).to eq(200)

      expenses = JSON.parse(last_response.body)
      expect(expenses).to contain_exactly(coffee, zoo)

      header 'Accept', 'text/xml'
      get '/expenses/2017-06-12'
      expect(last_response.status).to eq(200)

      expenses = Ox.parse_obj(last_response.body)
      expect(expenses[0]).to include(payee: 'Whole Foods')
    end
  end
end
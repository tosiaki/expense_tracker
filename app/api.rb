require 'sinatra/base'
require 'json'
require 'ox'
require_relative 'ledger'
require_relative 'adapters'

module ExpenseTracker
  class API < Sinatra::Base
    def initialize(ledger: Ledger.new)
      @ledger = ledger
      super()
    end

    post '/expenses' do
      if env['CONTENT_TYPE'] == 'text/xml'
        data_handler = XMLAdapter.new
      else
        data_handler = JSON
      end

      expense = data_handler.parse(request.body.read)

      result = @ledger.record(expense)

      if result.success?
        data_handler.generate('expense_id' => result.expense_id)
      else
        status 422
        data_handler.generate('error' => result.error_message)
      end
    end

    get '/expenses/:date' do
      if env['HTTP_ACCEPT'] == 'text/xml'
        data_handler = XMLAdapter.new
      else
        data_handler = JSON
      end
      data_handler.generate(@ledger.expenses_on(params['date']))
    end
  end
end
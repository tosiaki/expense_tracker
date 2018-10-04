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
      if request.media_type == 'text/xml'
        data_handler = XMLAdapter.new
      elsif request.media_type == 'application/json'
        data_handler = JSON
      else
        status 422
        return JSON.generate('error' => 'Unsupported format')
      end

      begin
        expense = data_handler.parse(request.body.read)
      rescue JSON::ParserError, Ox::ParseError
        status 415
        return JSON.generate('error' => 'Format mismatch')
      end

      result = @ledger.record(expense)

      if result.success?
        data_handler.generate('expense_id' => result.expense_id)
      else
        status 422
        data_handler.generate('error' => result.error_message)
      end
    end

    get '/expenses/:date' do
      if request.accept? 'application/json'
        data_handler = JSON
        headers 'Content-Type' => 'application/json'
      elsif request.accept? 'text/xml'
        data_handler = XMLAdapter.new
        headers 'Content-Type' => 'text/xml'
      else
        status 406
        return
      end
      data_handler.generate(@ledger.expenses_on(params['date']))
    end
  end
end
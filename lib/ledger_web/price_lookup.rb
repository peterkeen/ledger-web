require 'csv'
require 'uri'
require 'net/http'

module LedgerWeb
  class YahooPriceLookup
    def initialize(symbol, min_date, max_date)
      @symbol = symbol.gsub(/"/,'')
      @min_date = min_date
      @max_date = max_date
    end

    def lookup
      params = {
        'a' => @min_date.month - 1,
        'b' => @min_date.day,
        'c' => @min_date.year,
        'd' => @max_date.month - 1,
        'e' => @max_date.day,
        'f' => @max_date.year,
        's' => @symbol,
        'ignore' => '.csv',
      }

      query = params.map { |k,v| "#{k}=#{v}" }.join("&")
      response = RestClient.get("https://ichart.finance.yahoo.com/table.csv?#{query}")

      if response.code != 200
        return []
      end

      rows = []
      CSV.parse(response.body, :headers => true) do |row|
        rows << [Date.parse(row["Date"]), row["Close"].to_f]
      end
      rows
    end
  end
end


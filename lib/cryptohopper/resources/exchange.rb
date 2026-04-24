# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.exchange` — public market data (no auth required).
    class Exchange
      def initialize(client)
        @client = client
      end

      def ticker(exchange:, market:)
        @client._request("GET", "/exchange/ticker",
                         params: { exchange: exchange, market: market })
      end

      def candles(exchange:, market:, timeframe:, from: nil, to: nil)
        @client._request(
          "GET", "/exchange/candle",
          params: {
            exchange: exchange, market: market, timeframe: timeframe,
            from: from, to: to
          }
        )
      end

      def orderbook(exchange:, market:)
        @client._request("GET", "/exchange/orderbook",
                         params: { exchange: exchange, market: market })
      end

      def markets(exchange)
        @client._request("GET", "/exchange/markets",
                         params: { exchange: exchange })
      end

      def currencies(exchange)
        @client._request("GET", "/exchange/currencies",
                         params: { exchange: exchange })
      end

      def exchanges
        @client._request("GET", "/exchange/exchanges")
      end

      def forex_rates
        @client._request("GET", "/exchange/forex-rates")
      end
    end
  end
end

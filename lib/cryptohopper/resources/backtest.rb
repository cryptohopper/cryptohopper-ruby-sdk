# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.backtest` — run and inspect backtests.
    class Backtests
      def initialize(client)
        @client = client
      end

      def create(data)
        @client._request("POST", "/backtest/new", body: data)
      end

      def get(backtest_id)
        @client._request("GET", "/backtest/get",
                         params: { backtest_id: backtest_id })
      end

      def list(**params)
        @client._request("GET", "/backtest/list",
                         params: params.empty? ? nil : params)
      end

      def cancel(backtest_id)
        @client._request("POST", "/backtest/cancel",
                         body: { backtest_id: backtest_id })
      end

      def restart(backtest_id)
        @client._request("POST", "/backtest/restart",
                         body: { backtest_id: backtest_id })
      end

      def limits
        @client._request("GET", "/backtest/limits")
      end
    end
  end
end

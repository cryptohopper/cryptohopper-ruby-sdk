# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.arbitrage` — exchange + market arbitrage + shared backlog.
    class Arbitrage
      def initialize(client)
        @client = client
      end

      # ─── Cross-exchange arbitrage ─────────────────────────────────────

      def exchange_start(data)
        @client._request("POST", "/arbitrage/exchange", body: data)
      end

      def exchange_cancel(data = {})
        @client._request("POST", "/arbitrage/cancel", body: data)
      end

      def exchange_results(**params)
        @client._request("GET", "/arbitrage/results",
                         params: params.empty? ? nil : params)
      end

      def exchange_history(**params)
        @client._request("GET", "/arbitrage/history",
                         params: params.empty? ? nil : params)
      end

      def exchange_total
        @client._request("GET", "/arbitrage/total")
      end

      def exchange_reset_total
        @client._request("POST", "/arbitrage/resettotal", body: {})
      end

      # ─── Intra-exchange market arbitrage ──────────────────────────────

      def market_start(data)
        @client._request("POST", "/arbitrage/market", body: data)
      end

      def market_cancel(data = {})
        @client._request("POST", "/arbitrage/market-cancel", body: data)
      end

      def market_result(**params)
        @client._request("GET", "/arbitrage/market-result",
                         params: params.empty? ? nil : params)
      end

      def market_history(**params)
        @client._request("GET", "/arbitrage/market-history",
                         params: params.empty? ? nil : params)
      end

      # ─── Backlog (shared) ─────────────────────────────────────────────

      def backlogs(**params)
        @client._request("GET", "/arbitrage/get-backlogs",
                         params: params.empty? ? nil : params)
      end

      def backlog(backlog_id)
        @client._request("GET", "/arbitrage/get-backlog",
                         params: { backlog_id: backlog_id })
      end

      def delete_backlog(backlog_id)
        @client._request("POST", "/arbitrage/delete-backlog",
                         body: { backlog_id: backlog_id })
      end
    end
  end
end

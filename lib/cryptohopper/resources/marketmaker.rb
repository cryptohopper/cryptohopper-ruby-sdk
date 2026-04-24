# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.marketmaker` — market-maker bot ops + market-trend overrides + backlog.
    class MarketMaker
      def initialize(client)
        @client = client
      end

      def get(**params)
        @client._request("GET", "/marketmaker/get",
                         params: params.empty? ? nil : params)
      end

      def cancel(data = {})
        @client._request("POST", "/marketmaker/cancel", body: data)
      end

      def history(**params)
        @client._request("GET", "/marketmaker/history",
                         params: params.empty? ? nil : params)
      end

      # Market-trend overrides

      def get_market_trend(**params)
        @client._request("GET", "/marketmaker/get-market-trend",
                         params: params.empty? ? nil : params)
      end

      def set_market_trend(data)
        @client._request("POST", "/marketmaker/set-market-trend", body: data)
      end

      def delete_market_trend(data = {})
        @client._request("POST", "/marketmaker/delete-market-trend", body: data)
      end

      # Backlog

      def backlogs(**params)
        @client._request("GET", "/marketmaker/get-backlogs",
                         params: params.empty? ? nil : params)
      end

      def backlog(backlog_id)
        @client._request("GET", "/marketmaker/get-backlog",
                         params: { backlog_id: backlog_id })
      end

      def delete_backlog(backlog_id)
        @client._request("POST", "/marketmaker/delete-backlog",
                         body: { backlog_id: backlog_id })
      end
    end
  end
end

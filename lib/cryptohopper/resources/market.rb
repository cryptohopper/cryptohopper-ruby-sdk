# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.market` — marketplace browse (public).
    class Market
      def initialize(client)
        @client = client
      end

      def signals(**params)
        @client._request("GET", "/market/signals",
                         params: params.empty? ? nil : params)
      end

      def signal(signal_id)
        @client._request("GET", "/market/signal",
                         params: { signal_id: signal_id })
      end

      def items(**params)
        @client._request("GET", "/market/marketitems",
                         params: params.empty? ? nil : params)
      end

      def item(item_id)
        @client._request("GET", "/market/marketitem",
                         params: { item_id: item_id })
      end

      def homepage
        @client._request("GET", "/market/homepage")
      end
    end
  end
end

# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.signals` — signal-provider analytics.
    # Distinct from the marketplace browse at `client.market.signals`.
    class Signals
      def initialize(client)
        @client = client
      end

      def list(**params)
        @client._request("GET", "/signals/signals",
                         params: params.empty? ? nil : params)
      end

      def performance(**params)
        @client._request("GET", "/signals/performance",
                         params: params.empty? ? nil : params)
      end

      def stats
        @client._request("GET", "/signals/stats")
      end

      def distribution
        @client._request("GET", "/signals/distribution")
      end

      def chart_data(**params)
        @client._request("GET", "/signals/chartdata",
                         params: params.empty? ? nil : params)
      end
    end
  end
end

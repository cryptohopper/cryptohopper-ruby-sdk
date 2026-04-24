# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.app` — mobile app store receipts + in-app purchases.
    class App
      def initialize(client)
        @client = client
      end

      def receipt(data)
        @client._request("POST", "/app/receipt", body: data)
      end

      def in_app_purchase(data)
        @client._request("POST", "/app/in_app_purchase", body: data)
      end
    end
  end
end

# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.chart` — saved chart layouts + shared chart links.
    class Chart
      def initialize(client)
        @client = client
      end

      def list
        @client._request("GET", "/chart/list")
      end

      def get(chart_id)
        @client._request("GET", "/chart/get", params: { chart_id: chart_id })
      end

      def save(data)
        @client._request("POST", "/chart/save", body: data)
      end

      def delete(chart_id)
        @client._request("POST", "/chart/delete", body: { chart_id: chart_id })
      end

      def share_save(data)
        @client._request("POST", "/chart/share-save", body: data)
      end

      def share_get(share_id)
        @client._request("GET", "/chart/share-get",
                         params: { share_id: share_id })
      end
    end
  end
end

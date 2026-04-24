# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.strategy` — user-defined trading strategies.
    class Strategies
      def initialize(client)
        @client = client
      end

      def list
        @client._request("GET", "/strategy/strategies")
      end

      def get(strategy_id)
        @client._request("GET", "/strategy/get",
                         params: { strategy_id: strategy_id })
      end

      def create(data)
        @client._request("POST", "/strategy/create", body: data)
      end

      def update(strategy_id, data)
        @client._request("POST", "/strategy/edit",
                         body: { strategy_id: strategy_id }.merge(data))
      end

      def delete(strategy_id)
        @client._request("POST", "/strategy/delete",
                         body: { strategy_id: strategy_id })
      end
    end
  end
end

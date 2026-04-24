# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.hoppers` — user trading bots (CRUD, positions, orders, trade, config).
    class Hoppers
      def initialize(client)
        @client = client
      end

      def list(exchange: nil)
        params = exchange ? { exchange: exchange } : nil
        @client._request("GET", "/hopper/list", params: params)
      end

      def get(hopper_id)
        @client._request("GET", "/hopper/get", params: { hopper_id: hopper_id })
      end

      def create(data)
        @client._request("POST", "/hopper/create", body: data)
      end

      def update(hopper_id, data)
        @client._request("POST", "/hopper/update",
                         body: { hopper_id: hopper_id }.merge(data))
      end

      def delete(hopper_id)
        @client._request("POST", "/hopper/delete", body: { hopper_id: hopper_id })
      end

      def positions(hopper_id)
        @client._request("GET", "/hopper/positions",
                         params: { hopper_id: hopper_id })
      end

      def position(hopper_id, position_id)
        @client._request(
          "GET", "/hopper/position",
          params: { hopper_id: hopper_id, position_id: position_id }
        )
      end

      def orders(hopper_id, **extra)
        @client._request("GET", "/hopper/orders",
                         params: { hopper_id: hopper_id }.merge(extra))
      end

      def buy(data)
        @client._request("POST", "/hopper/buy", body: data)
      end

      def sell(data)
        @client._request("POST", "/hopper/sell", body: data)
      end

      def config_get(hopper_id)
        @client._request("GET", "/hopper/configget",
                         params: { hopper_id: hopper_id })
      end

      def config_update(hopper_id, config)
        @client._request("POST", "/hopper/configupdate",
                         body: { hopper_id: hopper_id }.merge(config))
      end

      def config_pools(hopper_id)
        @client._request("GET", "/hopper/configpools",
                         params: { hopper_id: hopper_id })
      end

      def panic(hopper_id)
        @client._request("POST", "/hopper/panic", body: { hopper_id: hopper_id })
      end
    end
  end
end

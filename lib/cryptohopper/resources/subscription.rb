# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.subscription` — plans, per-hopper state, credits, billing.
    class Subscription
      def initialize(client)
        @client = client
      end

      def hopper(hopper_id)
        @client._request("GET", "/subscription/hopper",
                         params: { hopper_id: hopper_id })
      end

      def get
        @client._request("GET", "/subscription/get")
      end

      def plans
        @client._request("GET", "/subscription/plans")
      end

      def remap(data)
        @client._request("POST", "/subscription/remap", body: data)
      end

      def assign(data)
        @client._request("POST", "/subscription/assign", body: data)
      end

      def get_credits
        @client._request("GET", "/subscription/getcredits")
      end

      def order_sub(data)
        @client._request("POST", "/subscription/ordersub", body: data)
      end

      def stop_subscription(data = {})
        @client._request("POST", "/subscription/stopsubscription", body: data)
      end
    end
  end
end

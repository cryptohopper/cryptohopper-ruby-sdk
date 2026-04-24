# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.webhooks` — developer webhook registration.
    # Maps to the server's `/api/webhook_*` endpoints; named for clarity.
    class Webhooks
      def initialize(client)
        @client = client
      end

      def create(data)
        @client._request("POST", "/api/webhook_create", body: data)
      end

      def delete(webhook_id)
        @client._request("POST", "/api/webhook_delete",
                         body: { webhook_id: webhook_id })
      end
    end
  end
end

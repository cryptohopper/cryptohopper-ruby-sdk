# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.template` — bot templates (reusable hopper configurations).
    class Templates
      def initialize(client)
        @client = client
      end

      def list
        @client._request("GET", "/template/templates")
      end

      def get(template_id)
        @client._request("GET", "/template/get",
                         params: { template_id: template_id })
      end

      def basic(template_id)
        @client._request("GET", "/template/basic",
                         params: { template_id: template_id })
      end

      def save(data)
        @client._request("POST", "/template/save-template", body: data)
      end

      def update(template_id, data)
        @client._request("POST", "/template/update",
                         body: { template_id: template_id }.merge(data))
      end

      def load(template_id, hopper_id)
        @client._request(
          "POST", "/template/load",
          body: { template_id: template_id, hopper_id: hopper_id }
        )
      end

      def delete(template_id)
        @client._request("POST", "/template/delete",
                         body: { template_id: template_id })
      end
    end
  end
end

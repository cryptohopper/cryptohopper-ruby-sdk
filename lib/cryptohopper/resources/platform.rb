# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.platform` — marketing / i18n / discovery reads (all public).
    class Platform
      def initialize(client)
        @client = client
      end

      def latest_blog(**params)
        @client._request("GET", "/platform/latestblog",
                         params: params.empty? ? nil : params)
      end

      def documentation(**params)
        @client._request("GET", "/platform/documentation",
                         params: params.empty? ? nil : params)
      end

      def promo_bar
        @client._request("GET", "/platform/promobar")
      end

      def search_documentation(query)
        @client._request("GET", "/platform/searchdocumentation",
                         params: { q: query })
      end

      def countries
        @client._request("GET", "/platform/countries")
      end

      def country_allowlist
        @client._request("GET", "/platform/countryallowlist")
      end

      def ip_country
        @client._request("GET", "/platform/ipcountry")
      end

      def languages
        @client._request("GET", "/platform/languages")
      end

      def bot_types
        @client._request("GET", "/platform/bottypes")
      end
    end
  end
end

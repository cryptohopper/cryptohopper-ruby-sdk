# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.user` — authenticated user profile.
    class User
      def initialize(client)
        @client = client
      end

      # Fetch the authenticated user's profile. Requires `user` scope.
      def get
        @client._request("GET", "/user/get")
      end
    end
  end
end

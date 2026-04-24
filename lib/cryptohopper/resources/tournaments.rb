# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.tournaments` — trading competitions.
    class Tournaments
      def initialize(client)
        @client = client
      end

      def list(**params)
        @client._request("GET", "/tournaments/gettournaments",
                         params: params.empty? ? nil : params)
      end

      def active
        @client._request("GET", "/tournaments/active")
      end

      def get(tournament_id)
        @client._request("GET", "/tournaments/gettournament",
                         params: { tournament_id: tournament_id })
      end

      def search(query)
        @client._request("GET", "/tournaments/search", params: { q: query })
      end

      def trades(tournament_id)
        @client._request("GET", "/tournaments/trades",
                         params: { tournament_id: tournament_id })
      end

      def stats(tournament_id)
        @client._request("GET", "/tournaments/stats",
                         params: { tournament_id: tournament_id })
      end

      def activity(tournament_id)
        @client._request("GET", "/tournaments/activity",
                         params: { tournament_id: tournament_id })
      end

      def leaderboard(**params)
        @client._request("GET", "/tournaments/leaderboard",
                         params: params.empty? ? nil : params)
      end

      def tournament_leaderboard(tournament_id)
        @client._request("GET", "/tournaments/leaderboard_tournament",
                         params: { tournament_id: tournament_id })
      end

      def join(tournament_id, data = {})
        @client._request(
          "POST", "/tournaments/join",
          body: { tournament_id: tournament_id }.merge(data)
        )
      end

      def leave(tournament_id)
        @client._request("POST", "/tournaments/leave",
                         body: { tournament_id: tournament_id })
      end
    end
  end
end

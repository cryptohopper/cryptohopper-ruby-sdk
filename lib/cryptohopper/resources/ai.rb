# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.ai` — AI credits + LLM analysis.
    class AI
      def initialize(client)
        @client = client
      end

      def list(**params)
        @client._request("GET", "/ai/list", params: params.empty? ? nil : params)
      end

      def get(id)
        @client._request("GET", "/ai/get", params: { id: id })
      end

      def available_models
        @client._request("GET", "/ai/availablemodels")
      end

      # ─── Credits ─────────────────────────────────────────────────────

      def get_credits
        @client._request("GET", "/ai/getaicredits")
      end

      def credit_invoices(**params)
        @client._request("GET", "/ai/aicreditinvoices",
                         params: params.empty? ? nil : params)
      end

      def credit_transactions(**params)
        @client._request("GET", "/ai/aicredittransactions",
                         params: params.empty? ? nil : params)
      end

      def buy_credits(data)
        @client._request("POST", "/ai/buyaicredits", body: data)
      end

      # ─── LLM analysis ────────────────────────────────────────────────

      def llm_analyze_options
        @client._request("GET", "/ai/aillmanalyzeoptions")
      end

      def llm_analyze(data)
        @client._request("POST", "/ai/doaillmanalyze", body: data)
      end

      def llm_analyze_results(**params)
        @client._request("GET", "/ai/aillmanalyzeresults",
                         params: params.empty? ? nil : params)
      end

      def llm_results(**params)
        @client._request("GET", "/ai/aillmresults",
                         params: params.empty? ? nil : params)
      end
    end
  end
end

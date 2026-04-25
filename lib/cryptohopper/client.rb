# frozen_string_literal: true

require "json"
require "net/http"
require "timeout"
require "uri"

require_relative "errors"
require_relative "version"
require_relative "resources/user"
require_relative "resources/hoppers"
require_relative "resources/exchange"
require_relative "resources/strategy"
require_relative "resources/backtest"
require_relative "resources/market"
require_relative "resources/signals"
require_relative "resources/arbitrage"
require_relative "resources/marketmaker"
require_relative "resources/template"
require_relative "resources/ai"
require_relative "resources/platform"
require_relative "resources/chart"
require_relative "resources/subscription"
require_relative "resources/social"
require_relative "resources/tournaments"
require_relative "resources/webhooks"
require_relative "resources/app"

module Cryptohopper
  DEFAULT_BASE_URL = "https://api.cryptohopper.com/v1"
  DEFAULT_TIMEOUT = 30
  DEFAULT_MAX_RETRIES = 3

  # Synchronous Cryptohopper API client.
  #
  # @example
  #   ch = Cryptohopper::Client.new(api_key: ENV.fetch("CRYPTOHOPPER_TOKEN"))
  #   me = ch.user.get
  #   ticker = ch.exchange.ticker(exchange: "binance", market: "BTC/USDT")
  class Client
    attr_reader :base_url,
                :user, :hoppers, :exchange, :strategy, :backtest, :market,
                :signals, :arbitrage, :marketmaker, :template,
                :ai, :platform, :chart, :subscription,
                :social, :tournaments, :webhooks, :app

    # @param api_key [String] 40-char OAuth2 bearer token.
    # @param app_key [String, nil] Optional OAuth client_id, sent as
    #   `x-api-app-key`.
    # @param base_url [String, nil] Override for staging.
    # @param timeout [Integer, Float] Per-request timeout in seconds.
    # @param max_retries [Integer] Retries on 429 (respecting Retry-After).
    # @param user_agent [String, nil] Appended after `cryptohopper-sdk-ruby/<v>`.
    # rubocop:disable Metrics/ParameterLists -- keyword args; readability
    # wins over splitting into a value-object struct.
    def initialize(api_key:, app_key: nil, base_url: nil, timeout: DEFAULT_TIMEOUT,
                   max_retries: DEFAULT_MAX_RETRIES, user_agent: nil)
      raise ArgumentError, "api_key is required" if api_key.nil? || api_key.empty?

      @api_key = api_key
      @app_key = app_key
      @base_url = (base_url || DEFAULT_BASE_URL).chomp("/")
      @timeout = timeout
      @max_retries = max_retries
      @user_agent_suffix = user_agent

      @user = Resources::User.new(self)
      @hoppers = Resources::Hoppers.new(self)
      @exchange = Resources::Exchange.new(self)
      @strategy = Resources::Strategies.new(self)
      @backtest = Resources::Backtests.new(self)
      @market = Resources::Market.new(self)
      @signals = Resources::Signals.new(self)
      @arbitrage = Resources::Arbitrage.new(self)
      @marketmaker = Resources::MarketMaker.new(self)
      @template = Resources::Templates.new(self)
      @ai = Resources::AI.new(self)
      @platform = Resources::Platform.new(self)
      @chart = Resources::Chart.new(self)
      @subscription = Resources::Subscription.new(self)
      @social = Resources::Social.new(self)
      @tournaments = Resources::Tournaments.new(self)
      @webhooks = Resources::Webhooks.new(self)
      @app = Resources::App.new(self)
    end
    # rubocop:enable Metrics/ParameterLists

    # Internal transport. Resources call this. Users shouldn't.
    #
    # @api private
    def _request(method, path, params: nil, body: nil, max_retries: nil)
      retries = max_retries || @max_retries
      attempt = 0
      loop do
        return do_request(method, path, params: params, body: body)
      rescue Error => e
        raise unless e.code == "RATE_LIMITED" && attempt < retries

        wait = e.retry_after_ms ? e.retry_after_ms / 1000.0 : (2**attempt)
        sleep(wait)
        attempt += 1
      end
    end

    private

    def do_request(method, path, params:, body:)
      uri = build_uri(path, params)
      req = build_request(method, uri, body)
      response = send_request(uri, req)
      handle_response(response)
    end

    def build_uri(path, params)
      full_path = path.start_with?("/") ? path : "/#{path}"
      url = "#{@base_url}#{full_path}"

      if params && !params.empty?
        clean = params.compact
        unless clean.empty?
          qs = URI.encode_www_form(clean.transform_keys(&:to_s))
          url += (url.include?("?") ? "&" : "?") + qs
        end
      end

      URI.parse(url)
    end

    def build_request(method, uri, body)
      klass = case method.to_s.upcase
              when "GET"    then Net::HTTP::Get
              when "POST"   then Net::HTTP::Post
              when "PATCH"  then Net::HTTP::Patch
              when "DELETE" then Net::HTTP::Delete
              else raise ArgumentError, "Unsupported method: #{method}"
              end

      req = klass.new(uri.request_uri)
      req["Authorization"] = "Bearer #{@api_key}"
      req["Accept"] = "application/json"
      req["User-Agent"] = user_agent_header
      # Ruby treats empty strings as truthy, so a literal `if @app_key`
      # would set the header to an empty string when `app_key:` is "".
      # Skip the header entirely unless we have a non-empty value.
      req["x-api-app-key"] = @app_key if @app_key && !@app_key.empty?

      if body
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(body)
      end

      req
    end

    def send_request(uri, req)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @timeout
      http.read_timeout = @timeout
      http.write_timeout = @timeout if http.respond_to?(:write_timeout=)

      # Net::HTTP's `read_timeout` is per-read — a server trickling response
      # bytes faster than the timeout resets the clock with each chunk and
      # the call hangs indefinitely. Wrap in `Timeout.timeout` so the
      # configured `@timeout` becomes a true total deadline. Each call uses
      # a one-shot connection (no `http.start`), so a Timeout interrupt
      # can't leave a session in a bad state.
      Timeout.timeout(@timeout) { http.request(req) }
    rescue Timeout::Error => e
      # Net::OpenTimeout / ReadTimeout / WriteTimeout all subclass
      # Timeout::Error in modern Ruby — rescuing the parent catches all four.
      raise Error.new(code: "TIMEOUT", message: "Request timed out (#{e.message})",
                      status: 0)
    rescue StandardError => e
      raise Error.new(code: "NETWORK_ERROR",
                      message: "Could not reach #{@base_url} (#{e.message})",
                      status: 0)
    end

    def handle_response(response)
      status = response.code.to_i
      raw = response.body.to_s
      parsed = parse_json(raw)

      raise build_error(status, parsed, response) if status >= 400

      return parsed["data"] if parsed.is_a?(Hash) && parsed.key?("data")

      parsed
    end

    def parse_json(raw)
      return nil if raw.empty?

      JSON.parse(raw)
    rescue JSON::ParserError
      nil
    end

    def build_error(status, parsed, response)
      body = parsed.is_a?(Hash) ? parsed : {}
      message = body["message"] || "Request failed (#{status})"
      raw_server_code = body["code"]
      server_code = raw_server_code.is_a?(Integer) && raw_server_code.positive? ? raw_server_code : nil
      ip_address = body["ip_address"].is_a?(String) ? body["ip_address"] : nil
      retry_after_ms = parse_retry_after(response["retry-after"])

      Error.new(
        code: default_code_for_status(status),
        message: message,
        status: status,
        server_code: server_code,
        ip_address: ip_address,
        retry_after_ms: retry_after_ms
      )
    end

    def default_code_for_status(status)
      case status
      when 400, 422 then "VALIDATION_ERROR"
      when 401      then "UNAUTHORIZED"
      when 402      then "DEVICE_UNAUTHORIZED"
      when 403      then "FORBIDDEN"
      when 404      then "NOT_FOUND"
      when 409      then "CONFLICT"
      when 429      then "RATE_LIMITED"
      when 503      then "SERVICE_UNAVAILABLE"
      else status >= 500 ? "SERVER_ERROR" : "UNKNOWN"
      end
    end

    def parse_retry_after(header)
      return nil if header.nil? || header.empty?

      seconds = Float(header, exception: false)
      return nil if seconds&.negative?
      return (seconds * 1000).round if seconds

      # HTTP-date fallback.
      require "time"
      begin
        when_date = Time.httpdate(header)
      rescue ArgumentError
        return nil
      end
      delta_ms = ((when_date - Time.now) * 1000).round
      [delta_ms, 0].max
    end

    def user_agent_header
      base = "cryptohopper-sdk-ruby/#{VERSION}"
      @user_agent_suffix ? "#{base} #{@user_agent_suffix}" : base
    end
  end
end

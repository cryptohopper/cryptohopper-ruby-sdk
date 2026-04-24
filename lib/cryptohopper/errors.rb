# frozen_string_literal: true

module Cryptohopper
  # Single exception raised by every SDK call on non-2xx responses (and on
  # network/timeout failures). Unknown server codes pass through as-is on
  # `#code` so callers can handle new codes without waiting for an SDK
  # update.
  class Error < StandardError
    KNOWN_CODES = %w[
      VALIDATION_ERROR
      UNAUTHORIZED
      FORBIDDEN
      NOT_FOUND
      CONFLICT
      RATE_LIMITED
      SERVER_ERROR
      SERVICE_UNAVAILABLE
      DEVICE_UNAUTHORIZED
      NETWORK_ERROR
      TIMEOUT
      UNKNOWN
    ].freeze

    attr_reader :code, :status, :server_code, :ip_address, :retry_after_ms

    def initialize(code:, message:, status:, server_code: nil, ip_address: nil,
                   retry_after_ms: nil)
      super(message)
      @code = code
      @status = status
      @server_code = server_code
      @ip_address = ip_address
      @retry_after_ms = retry_after_ms
    end

    def inspect
      extras = []
      extras << "server_code=#{@server_code}" if @server_code
      extras << "ip=#{@ip_address}" if @ip_address
      extras << "retry_after_ms=#{@retry_after_ms}" if @retry_after_ms
      extra = extras.empty? ? "" : " (#{extras.join(", ")})"
      "#<Cryptohopper::Error code=#{@code} status=#{@status}#{extra}: #{message}>"
    end
  end
end

# frozen_string_literal: true

require_relative "cryptohopper/version"
require_relative "cryptohopper/errors"
require_relative "cryptohopper/client"

# Official Ruby SDK for the Cryptohopper API.
#
# @example
#   require "cryptohopper"
#
#   ch = Cryptohopper::Client.new(api_key: ENV.fetch("CRYPTOHOPPER_TOKEN"))
#   me = ch.user.get
#   ticker = ch.exchange.ticker(exchange: "binance", market: "BTC/USDT")
module Cryptohopper
end

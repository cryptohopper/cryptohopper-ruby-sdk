# cryptohopper

[![Gem Version](https://badge.fury.io/rb/cryptohopper.svg)](https://rubygems.org/gems/cryptohopper)

Official Ruby SDK for the [Cryptohopper](https://www.cryptohopper.com) API.

> **Status: 0.1.0.pre.alpha.1** — full coverage of all 18 public API domains from day one. Matches the feature surface of `@cryptohopper/sdk`, `cryptohopper` (Python), and `cryptohopper-go-sdk` at v0.4.0.

## Install

```bash
bundle add cryptohopper
```

Or, in your `Gemfile`:

```ruby
gem "cryptohopper"
```

Requires Ruby 3.2+.

## Quickstart

```ruby
require "cryptohopper"

ch = Cryptohopper::Client.new(api_key: ENV.fetch("CRYPTOHOPPER_TOKEN"))

me = ch.user.get
puts me["email"]

ticker = ch.exchange.ticker(exchange: "binance", market: "BTC/USDT")
puts ticker["last"]
```

## Authentication

Cryptohopper uses OAuth2 bearer tokens:

1. Sign in at [cryptohopper.com](https://www.cryptohopper.com) → developer dashboard.
2. Create an OAuth application — you'll receive a `client_id` and `client_secret`.
3. Drive the OAuth consent flow to receive a 40-character bearer token.

```ruby
ch = Cryptohopper::Client.new(
  api_key: ENV.fetch("CRYPTOHOPPER_TOKEN"),
  app_key: ENV["CRYPTOHOPPER_CLIENT_ID"], # optional, sent as x-api-app-key
)
```

## Resources

```ruby
# User
ch.user.get

# Hoppers
ch.hoppers.list(exchange: "binance")
ch.hoppers.get(42)
ch.hoppers.buy(hopper_id: 42, market: "BTC/USDT", amount: 0.001)
ch.hoppers.config_update(42, strategy_id: 99)
ch.hoppers.panic(42)

# Exchange (public, no auth)
ch.exchange.ticker(exchange: "binance", market: "BTC/USDT")
ch.exchange.candles(exchange: "binance", market: "BTC/USDT", timeframe: "1h")

# Strategy / Backtest / Market
ch.strategy.list
ch.backtest.create(hopper_id: 42, from_date: "2026-01-01", to_date: "2026-03-01")
ch.market.signals(type: "buy")

# A1 domains
ch.signals.performance
ch.arbitrage.exchange_history
ch.marketmaker.get(hopper_id: 42)
ch.template.load(3, 42)  # apply template 3 to hopper 42

# A2 domains
ch.ai.get_credits
ch.ai.llm_analyze(strategy_id: 42)
ch.platform.bot_types
ch.chart.list
ch.subscription.plans

# A3 domains
ch.social.get_profile("pim")
ch.social.create_post(content: "New post")
ch.tournaments.active
ch.webhooks.create(url: "https://example.com/hook")
```

## Client options

| Option | Default | Description |
|---|---|---|
| `api_key:` | — (required) | OAuth2 bearer token |
| `app_key:` | `nil` | Optional OAuth `client_id`, sent as `x-api-app-key` |
| `base_url:` | `https://api.cryptohopper.com/v1` | Override for staging |
| `timeout:` | `30` | Per-request timeout in seconds |
| `max_retries:` | `3` | Retries on HTTP 429 (respects `Retry-After`). `0` disables auto-retry. |
| `user_agent:` | `nil` | Appended after `cryptohopper-sdk-ruby/<version>` |

## Errors

Every non-2xx response becomes a `Cryptohopper::Error`:

```ruby
begin
  ch.user.get
rescue Cryptohopper::Error => e
  puts e.code              # "UNAUTHORIZED" | "FORBIDDEN" | "RATE_LIMITED" | ...
  puts e.status            # HTTP status
  puts e.server_code       # numeric server code, if any
  puts e.ip_address        # client IP the server saw (helps debug IP whitelist)
  puts e.retry_after_ms    # ms to wait on 429
end
```

Codes: `UNAUTHORIZED`, `FORBIDDEN`, `NOT_FOUND`, `RATE_LIMITED`, `VALIDATION_ERROR`, `DEVICE_UNAUTHORIZED`, `SERVER_ERROR`, `NETWORK_ERROR`, `TIMEOUT`, `UNKNOWN`. Unknown server-side codes pass through verbatim.

## Rate limiting

The server enforces three buckets:

- `normal` — 30 requests/minute
- `order` — 8 orders per 8-second window
- `backtest` — 1 request per 2 seconds

On HTTP 429 the SDK retries with exponential backoff up to `max_retries` (default 3), respecting `Retry-After`. Pass `max_retries: 0` to disable auto-retry and handle 429s yourself.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Release

Push a `rb-v<version>` git tag. The release workflow runs the test suite, verifies tag-version parity, builds the gem, and publishes to RubyGems via **Trusted Publishing** (OIDC) — no long-lived API keys stored.

## Related packages

| Language | Package | Install |
|---|---|---|
| Node.js | [`@cryptohopper/sdk`](https://www.npmjs.com/package/@cryptohopper/sdk) | `npm i @cryptohopper/sdk` |
| Python | [`cryptohopper`](https://pypi.org/project/cryptohopper/) | `pip install cryptohopper` |
| Go | `github.com/cryptohopper/cryptohopper-go-sdk` | `go get github.com/cryptohopper/cryptohopper-go-sdk` |
| CLI | [`cryptohopper-cli`](https://github.com/cryptohopper/cryptohopper-cli) | GitHub Releases binaries |

## License

MIT — see [LICENSE](./LICENSE).

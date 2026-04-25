# Getting Started

## Install

```bash
gem install cryptohopper --pre
```

Or in your `Gemfile`:

```ruby
gem "cryptohopper", "~> 0.1.0.pre.alpha.1"
```

Then:

```bash
bundle install
```

Requires Ruby 3.1 or newer. The gem has zero non-stdlib runtime dependencies — `net/http`, `json`, `uri`, `time` carry the whole transport.

## First call

```ruby
require "cryptohopper"

ch = Cryptohopper::Client.new(api_key: ENV.fetch("CRYPTOHOPPER_TOKEN"))

me = ch.user.get
puts "Logged in as: #{me["email"]}"

ticker = ch.exchange.ticker(exchange: "binance", market: "BTC/USDT")
puts "BTC/USDT: #{ticker["last"]}"
```

`Cryptohopper::Client` is plain — no block-yielding constructor or context-manager equivalent is needed since the underlying `Net::HTTP` connections are short-lived per request. Just keep the client around and reuse it.

## Getting a token

Every request (except a handful of public endpoints like `/exchange/ticker`) needs an OAuth2 bearer token. Create one via **Developer → Create App** on [cryptohopper.com](https://www.cryptohopper.com) and complete the consent flow. The token is a 40-character opaque string.

For local dev:

```bash
export CRYPTOHOPPER_TOKEN=<your-token>
```

In production, load from your secret store of choice (Rails credentials, Vault, AWS Secrets Manager, etc.) at boot.

## Idiomatic patterns

### Exception handling with `rescue`

The SDK raises `Cryptohopper::Error` for every API failure. The class extends `StandardError`, so an unqualified `rescue` clause won't accidentally swallow it — but `rescue StandardError` (or bare `rescue`) will:

```ruby
begin
  ch.hoppers.get(999_999)
rescue Cryptohopper::Error => e
  case e.code
  when "NOT_FOUND"
    # expected — 404
  when "UNAUTHORIZED"
    refresh_token!
    retry
  when "RATE_LIMITED"
    # SDK already retried; back off harder
    sleep(e.retry_after_ms / 1000.0) if e.retry_after_ms
  else
    Rails.logger.error("cryptohopper: #{e.code}/#{e.status} #{e.message}")
    raise
  end
end
```

Compare error codes with `==` against the strings in `Cryptohopper::Error::KNOWN_CODES` — they're stable across SDK versions.

### Keyword arguments

Every method that takes named parameters uses Ruby 3 keyword args. Pass them by name:

```ruby
ch.exchange.ticker(exchange: "binance", market: "BTC/USDT")

ch.exchange.candles(
  exchange: "binance",
  market: "BTC/USDT",
  timeframe: "1h",
  from: 1_700_000_000,
  to: 1_700_864_000,
)
```

For methods that take a request body (typically POST endpoints), pass a hash:

```ruby
ch.hoppers.create({
  name: "My Bot",
  exchange: "binance",
  config_pool_id: 42,
})
```

### Customising the client

```ruby
ch = Cryptohopper::Client.new(
  api_key:     ENV.fetch("CRYPTOHOPPER_TOKEN"),
  app_key:     ENV["CRYPTOHOPPER_APP_KEY"],          # optional
  base_url:    "https://api.cryptohopper.com/v1",     # default
  timeout:     30,                                    # seconds; default 30
  max_retries: 3,                                     # 429 backoff; 0 disables
  user_agent:  "my-app/1.0",                          # appended to UA header
)
```

All keyword arguments except `api_key:` are optional.

## Common pitfalls

**`ArgumentError: api_key is required`** — empty string or `nil`. Most often you ran `ENV["CRYPTOHOPPER_TOKEN"]` (returns `nil` when unset) instead of `ENV.fetch("CRYPTOHOPPER_TOKEN")` (raises `KeyError`). Use `ENV.fetch` and let it fail loudly at boot.

**`Cryptohopper::Error: UNAUTHORIZED` on every call** — token is wrong, expired, or revoked. Check the app's status in the Cryptohopper dashboard.

**`Cryptohopper::Error: FORBIDDEN` on endpoints that used to work** — IP allowlisting on the OAuth app blocked your current IP. The error includes `ip_address` so you can see what Cryptohopper saw:

```ruby
rescue Cryptohopper::Error => e
  if e.code == "FORBIDDEN"
    puts "blocked from #{e.ip_address}"
  end
end
```

**`OpenSSL::SSL::SSLError: certificate verify failed`** — corporate proxy or self-signed root CA in the chain. Don't disable verification globally. Set `SSL_CERT_FILE` (or `SSL_CERT_DIR`) at the process level so `Net::HTTP` picks it up:

```bash
export SSL_CERT_FILE=/path/to/corporate-ca-bundle.pem
```

**Multi-threaded apps (Sidekiq, Puma) — share or per-thread?** `Cryptohopper::Client` is safe to share across threads as long as you don't mutate it (constructor args are frozen on init). One client serving the whole app is fine. The underlying `Net::HTTP` opens a fresh connection per request, so there's no shared connection pool to worry about.

If your app is heavily concurrent and you want to amortise the TCP/TLS handshake, you can pass a custom transport via `user_agent:` + your own `Net::HTTP.start { |http| ... }` block — but the SDK doesn't expose a hook for this directly; file an issue if it'd matter for you.

## Type signatures (RBS)

The gem doesn't ship RBS sigs yet — that's roadmap. In the meantime, response shapes are plain hashes (or arrays of hashes) keyed by string. Wrap with your own dataclass / Struct if you want stronger typing.

## Next steps

- [Authentication](Authentication.md) — bearer flow, app keys, IP whitelisting, rotating tokens
- [Error Handling](Error-Handling.md) — every error code, recovery patterns, structured logging
- [Rate Limits](Rate-Limits.md) — auto-retry, customising back-off, concurrent workers

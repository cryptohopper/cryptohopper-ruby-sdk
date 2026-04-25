# Authentication

Every SDK request (except a handful of public endpoints) requires an OAuth2 bearer token:

```
Authorization: Bearer <40-char token>
```

## Obtaining a token

1. Log in to [cryptohopper.com](https://www.cryptohopper.com).
2. **Developer → Create App** — gives you a `client_id` + `client_secret`.
3. Complete the OAuth consent flow for your app, which returns a bearer token.

Options to automate step 3:

- **The official CLI**: `cryptohopper login` opens the consent page, runs a loopback listener, and persists the token to `~/.cryptohopper/config.json`. You can read that file from Ruby and reuse the token.
- **Your own code**: call the server's `/oauth2/authorize` + `/oauth2/token` endpoints directly. The CLI's implementation is short (~300 lines of TypeScript) and a reasonable reference.

## Client construction

```ruby
ch = Cryptohopper::Client.new(
  api_key:     ENV.fetch("CRYPTOHOPPER_TOKEN"),
  app_key:     ENV["CRYPTOHOPPER_APP_KEY"],
  base_url:    "https://api.cryptohopper.com/v1",
  timeout:     30,
  max_retries: 3,
  user_agent:  "my-app/1.0",
)
```

The `api_key:` argument is required; everything else is optional.

### `app_key:`

Cryptohopper lets OAuth apps identify themselves on every request via the `x-api-app-key` header (value = your OAuth `client_id`). When set, the SDK adds the header automatically. Reasons to set it:

- Shows up in Cryptohopper's server-side telemetry — you can attribute your own traffic.
- Drives per-app rate limits — if two apps share a token, they get independent quotas.
- Harmless to omit; the server accepts unattributed requests.

### `base_url:`

Override for staging or a local dev server. The default is `https://api.cryptohopper.com/v1`. The trailing `/v1` is part of the base; resource paths are relative to it.

```ruby
ch = Cryptohopper::Client.new(
  api_key: token,
  base_url: "https://api.staging.cryptohopper.com/v1",
)
```

### `timeout:`

Per-request timeout in seconds. Defaults to 30. Both connect and read timeouts share this value.

The 429-retry path may stack additional time on top of this — set it conservatively if `max_retries:` is high.

### `max_retries:`

Number of automatic retries on HTTP 429. Default 3. Set to 0 to disable. See [Rate Limits](Rate-Limits.md) for details.

### `user_agent:`

Appended after the SDK's own User-Agent (`cryptohopper-sdk-ruby/<version>`). Set this to identify your client to Cryptohopper support if you ever need to debug something on their side.

## IP allowlisting

If your Cryptohopper app has IP allowlisting enabled, requests from unlisted IPs return `403 FORBIDDEN`. The SDK surfaces this as `Cryptohopper::Error` with `code == "FORBIDDEN"` and a populated `ip_address` field showing the IP Cryptohopper saw:

```ruby
begin
  ch.hoppers.list
rescue Cryptohopper::Error => e
  if e.code == "FORBIDDEN"
    puts "blocked from #{e.ip_address}"
  end
end
```

For CI where the runner IP isn't stable, either disable IP allowlisting for that app or route outbound traffic through a stable IP (NAT gateway, VPN, dedicated proxy).

## Rotating tokens

Cryptohopper bearer tokens are long-lived but can be revoked:

- Manually from the dashboard.
- When the user revokes consent.

The SDK surfaces revocation as `UNAUTHORIZED` on the next call. There is no automatic refresh-token handling in the SDK today — if your app uses refresh tokens, handle the `UNAUTHORIZED` branch by exchanging your refresh token for a new access token and constructing a fresh client:

```ruby
class CryptohopperWrapper
  def initialize
    @mutex = Mutex.new
    @client = build_client(load_token)
  end

  def call(&block)
    block.call(@client)
  rescue Cryptohopper::Error => e
    raise unless e.code == "UNAUTHORIZED"

    @mutex.synchronize do
      @client = build_client(refresh_token!)
    end
    block.call(@client)  # retry once with the fresh client
  end

  private

  def build_client(token)
    Cryptohopper::Client.new(api_key: token)
  end
end
```

The client's `api_key` is intentionally not mutable — construct a fresh client for token rotation. The cost is small and it sidesteps races where one in-flight request uses an old token while another uses the new.

## Concurrency

`Cryptohopper::Client` is safe to share across threads as long as nothing mutates it after construction (none of the public surface does). One client serving a Sidekiq pool, a Puma worker pool, or a `Concurrent::FixedThreadPool` is fine.

```ruby
require "concurrent"

pool = Concurrent::FixedThreadPool.new(8)

futures = hopper_ids.map do |id|
  Concurrent::Promises.future_on(pool) { ch.hoppers.get(id) }
end

results = Concurrent::Promises.zip(*futures).value!
```

See [Rate Limits](Rate-Limits.md) for guidance on capping concurrency at the API quota.

## Public-only access (no token)

A handful of endpoints accept anonymous calls:

- `/market/*` — marketplace browse
- `/platform/*` — i18n, country list, blog feed
- `/exchange/ticker`, `/exchange/candle`, `/exchange/orderbook`, `/exchange/markets`, `/exchange/exchanges`, `/exchange/forex-rates` — public market data

The SDK still requires `api_key:` at construction; pass any non-empty placeholder if you only intend to hit public endpoints. The server ignores the bearer header on whitelisted routes.

```ruby
ch = Cryptohopper::Client.new(api_key: "anonymous")
btc = ch.exchange.ticker(exchange: "binance", market: "BTC/USDT")
```

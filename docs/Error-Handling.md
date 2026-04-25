# Error Handling

Every non-2xx response and every transport failure raises `Cryptohopper::Error`. Same idea as the Node/Python/Go/Rust/PHP/Dart SDKs but laid out idiomatically as a single subclass of `StandardError` with reader attributes.

```ruby
begin
  ch.hoppers.get(999_999)
rescue Cryptohopper::Error => e
  e.code            # "NOT_FOUND"
  e.status          # 404
  e.message         # human-readable, from the server
  e.server_code     # numeric Cryptohopper code (or nil)
  e.ip_address      # server-reported caller IP (or nil)
  e.retry_after_ms  # only set on 429
end
```

`Cryptohopper::Error` extends `StandardError`, so a bare `rescue` (or `rescue StandardError`) will catch it. A bare `rescue` catching SDK errors and silently moving on is often a footgun — prefer `rescue Cryptohopper::Error`.

## Error code catalog

| `code` | HTTP | When you'll see it | Recover by |
|---|---|---|---|
| `VALIDATION_ERROR` | 400, 422 | Missing or malformed parameter | Fix the request; the message says which parameter |
| `UNAUTHORIZED` | 401 | Token missing, wrong, or revoked | Re-auth |
| `DEVICE_UNAUTHORIZED` | 402 | Internal Cryptohopper device-auth flow rejected you | Shouldn't happen via the public API; contact support |
| `FORBIDDEN` | 403 | Scope missing, or IP not allowlisted | Check `e.ip_address`; add to allowlist or grant the scope |
| `NOT_FOUND` | 404 | Resource or endpoint doesn't exist | Check the ID; check you're using the latest SDK |
| `CONFLICT` | 409 | Resource is in a conflicting state | Cancel the existing job or wait |
| `RATE_LIMITED` | 429 | Bucket exhausted | The SDK auto-retries; see [Rate Limits](Rate-Limits.md) |
| `SERVER_ERROR` | 500–502, 504 | Cryptohopper's end | Retry with back-off; report if persistent |
| `SERVICE_UNAVAILABLE` | 503 | Planned maintenance or downstream outage | Respect `retry_after_ms`; retry |
| `NETWORK_ERROR` | — | DNS failure, TCP reset, TLS handshake failure | Retry; check your network |
| `TIMEOUT` | — | Hit the client-side `timeout:` | Retry; bump timeout if the operation is legitimately slow |
| `UNKNOWN` | any | Anything else the SDK didn't recognise | Inspect `e.status` and `e.message` |

These strings are stable across SDK versions and are also exposed as `Cryptohopper::Error::KNOWN_CODES` — compare with `==`, never substring-match.

## Discriminating with a case statement

```ruby
def categorize(err)
  case err.code
  when "UNAUTHORIZED", "FORBIDDEN", "DEVICE_UNAUTHORIZED"
    :auth
  when "VALIDATION_ERROR"
    :bad_request
  when "NOT_FOUND"
    :not_found
  when "CONFLICT"
    :conflict
  when "RATE_LIMITED"
    :throttled
  when "SERVER_ERROR", "SERVICE_UNAVAILABLE"
    :server
  when "NETWORK_ERROR", "TIMEOUT"
    :transient
  else
    :unknown
  end
end
```

Future-proof your code by including a `:unknown` / `else` branch — the server can return codes the SDK doesn't recognise (they pass through as raw strings on `e.code`).

## A robust retry wrapper

```ruby
TRANSIENT_CODES = %w[SERVER_ERROR SERVICE_UNAVAILABLE NETWORK_ERROR TIMEOUT].freeze

def with_retry(max_attempts: 5, base_ms: 500)
  attempt = 1
  begin
    yield
  rescue Cryptohopper::Error => e
    raise unless TRANSIENT_CODES.include?(e.code) && attempt < max_attempts

    wait_ms = e.retry_after_ms || base_ms * 2**(attempt - 1)
    sleep(wait_ms / 1000.0)
    attempt += 1
    retry
  end
end

with_retry { ch.hoppers.list }
```

Don't include `RATE_LIMITED` in `TRANSIENT_CODES` — the SDK already retries 429s internally. Wrapping it here would multiply attempts unhelpfully.

## Structured logging

For Rails (`Rails.logger`) or `semantic_logger` / lograge / dry-logger, pull individual fields:

```ruby
rescue Cryptohopper::Error => e
  Rails.logger.error(
    event: "cryptohopper_error",
    code: e.code,
    status: e.status,
    server_code: e.server_code,
    ip: e.ip_address,
    retry_after_ms: e.retry_after_ms,
    message: e.message,
  )
end
```

### Sentry / Bugsnag / Honeybadger

When reporting to an exception tracker, attach the SDK's metadata as context so it's queryable in the dashboard. Example with Sentry:

```ruby
rescue Cryptohopper::Error => e
  Sentry.set_context("cryptohopper", {
    code: e.code,
    status: e.status,
    server_code: e.server_code,
    ip_address: e.ip_address,
  })
  Sentry.capture_exception(e)
  raise
end
```

This lets you filter Sentry events by `cryptohopper.code` to see, e.g., a spike of `RATE_LIMITED` after a deploy.

## Distinguishing transient from fatal

A common pattern is "retry only what's worth retrying":

```ruby
RETRYABLE = %w[SERVER_ERROR SERVICE_UNAVAILABLE NETWORK_ERROR TIMEOUT].freeze
FATAL     = %w[UNAUTHORIZED FORBIDDEN VALIDATION_ERROR NOT_FOUND CONFLICT].freeze

rescue Cryptohopper::Error => e
  if RETRYABLE.include?(e.code)
    enqueue_retry_later(...)
  elsif FATAL.include?(e.code)
    Rails.logger.warn("fatal cryptohopper error: #{e.code}")
    notify_user(e.message)
  else
    # RATE_LIMITED gets here only if SDK retries exhausted
    # UNKNOWN catches anything new the server returns
    raise
  end
end
```

## Idle-machine truthiness gotcha

`Cryptohopper::Error` instances respond to `present?` (Rails) as truthy and `blank?` as falsy — but inside a `begin/rescue` block, `e` is always non-nil. Don't write `if e.present?` to check whether a request failed; use the begin/rescue/else pattern:

```ruby
begin
  result = ch.hoppers.list
rescue Cryptohopper::Error => e
  handle_error(e)
else
  process(result)  # only runs when no exception
end
```

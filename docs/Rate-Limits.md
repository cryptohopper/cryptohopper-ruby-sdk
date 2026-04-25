# Rate Limits

Cryptohopper applies per-bucket rate limits on the server. When you hit one, you get a `429` with a `Retry-After` header. The SDK handles this for you.

## The default behaviour

On every `429`, the SDK:

1. Parses `Retry-After` (either seconds-as-integer or HTTP-date form) into milliseconds.
2. Sleeps that long (falling back to exponential back-off if the header is missing).
3. Retries the request.
4. Repeats up to `max_retries:` (default 3).

If retries exhaust, the call raises `Cryptohopper::Error` with `code == "RATE_LIMITED"` and `retry_after_ms` set to the last seen retry hint.

## Configuring it

```ruby
ch = Cryptohopper::Client.new(
  api_key:     token,
  max_retries: 10,    # default 3
  timeout:     60,    # seconds; bump if your retries push past 30s total
)
```

To **disable** retries entirely (e.g. you want to do your own back-off):

```ruby
ch = Cryptohopper::Client.new(api_key: token, max_retries: 0)
```

With `max_retries: 0` a 429 raises immediately as `RATE_LIMITED`. Inspect `e.retry_after_ms` and schedule the retry on your own timeline.

## Buckets

Cryptohopper has three named buckets:

| Bucket | Scope | Example endpoints |
|---|---|---|
| `normal` | Most reads + writes | `/user/get`, `/hopper/list`, `/hopper/update`, `/exchange/ticker` |
| `order` | Anything that places or modifies orders | `/hopper/buy`, `/hopper/sell`, `/hopper/panic` |
| `backtest` | The (expensive) backtest subsystem | `/backtest/new`, `/backtest/get` |

The SDK doesn't know which bucket a call hits — it only sees the 429. You don't need to either; the server tells you when you're limited.

## Backfill jobs (own back-off)

If you're ingesting historical data and need to fetch many pages, take ownership of the back-off:

```ruby
ch = Cryptohopper::Client.new(api_key: token, max_retries: 0)

all_hopper_ids.each do |hopper_id|
  loop do
    begin
      orders = ch.hoppers.orders(hopper_id)
      process(orders)
      break
    rescue Cryptohopper::Error => e
      raise unless e.code == "RATE_LIMITED"

      wait = (e.retry_after_ms || 1000) / 1000.0
      sleep(wait)
    end
  end
end
```

This pattern lets a long-running job honour rate limits without stalling other work, because you decide the pacing.

## Concurrency caps with concurrent-ruby

```ruby
require "concurrent"

MAX_CONCURRENT = 4
pool = Concurrent::FixedThreadPool.new(MAX_CONCURRENT)

futures = hopper_ids.map do |id|
  Concurrent::Promises.future_on(pool) { ch.hoppers.get(id) }
end

results = Concurrent::Promises.zip(*futures).value!
```

Empirically, **4–8 concurrent workers** is comfortable for most accounts. Higher is feasible with `app_key:` set (which gives your OAuth app its own quota) but plan to back off explicitly.

## Sidekiq workers

For background workers, use Sidekiq's per-queue concurrency setting:

```yaml
# config/sidekiq.yml
:concurrency: 4
:queues:
  - default
```

If a job hits `RATE_LIMITED` after the SDK's auto-retries exhaust, raise to let Sidekiq's retry machinery (with exponential back-off) handle the next attempt:

```ruby
class FetchHopperWorker
  include Sidekiq::Job

  sidekiq_options retry: 5, retry_in: ->(count, _exc) { 30 * (count + 1) }

  def perform(hopper_id)
    ch.hoppers.get(hopper_id)
  end
end
```

Sidekiq sees the `Cryptohopper::Error` (a `StandardError` subclass), retries with the back-off you configure, and DLQs after exhausting attempts.

## What the SDK does NOT do

- **No global semaphore.** If you spawn 50 threads each calling the SDK and the server rate-limits them, every thread's retry is independent — you might get 50 simultaneous sleeps. Cap concurrency yourself.
- **No adaptive slow-down.** After a 429, the SDK waits and retries that one call. It doesn't throttle future calls. If you see frequent 429s, lower your concurrency.
- **No client-side bucket tracking.** The server is the source of truth.

## Diagnosing "always rate-limited"

If every request raises `RATE_LIMITED` even at low volume:

1. Check that your app hasn't been flagged for abuse in the Cryptohopper dashboard.
2. Confirm you haven't accidentally written a rescue block that retries on non-429 errors too — `e.code == "RATE_LIMITED"` is the only guard the SDK applies internally.
3. Inspect `e.server_code` — Cryptohopper sometimes includes a numeric detail there that clarifies which bucket you've tripped.
4. Confirm you're not sharing one token across many machines (one quota, divided across all of them). If you have multiple environments, give each a distinct token + `app_key:` for clean attribution.

## Multi-instance Rails apps

Running multiple Rails app instances (e.g. behind a load balancer) with one shared `CRYPTOHOPPER_TOKEN`? They share a single quota across all instances. Either:

- Issue a separate OAuth app per environment / per instance group, or
- Set `app_key:` to distinct values per instance group so the server can attribute and bucket per-app.

The SDK doesn't try to coordinate quota across processes — that's a coordination problem (Redis, a rate-limit service like `rack-attack`, etc.).

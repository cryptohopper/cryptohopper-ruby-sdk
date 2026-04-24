# Changelog

All notable changes to the `cryptohopper` gem are documented in this file.
The format is loosely based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## 0.1.0.pre.alpha.1 — Unreleased

Initial release. Launches at full surface parity with the other SDKs at 0.4.0 — all 18 public API domains from day one.

### Transport
- `Cryptohopper::Client` — OAuth2 bearer auth, optional `app_key` sent as `x-api-app-key`, keyword-arg initialiser.
- `Cryptohopper::Error` — typed exception with `code`, `status`, `server_code`, `ip_address`, `retry_after_ms`.
- Automatic retry on HTTP 429 honouring `Retry-After` (default `max_retries: 3`, configurable/disableable).
- Stdlib only — `Net::HTTP` + `json`, no third-party runtime dependencies.

### Resources
- **Core** — `user`, `hoppers`, `exchange`, `strategy`, `backtest`, `market`
- **A1** — `signals`, `arbitrage`, `marketmaker`, `template`
- **A2** — `ai`, `platform`, `chart`, `subscription`
- **A3** — `social` (27 methods), `tournaments`, `webhooks`, `app`

Method names are snake_case per Ruby convention and mirror the Python SDK 1:1 (`get_credits`, `llm_analyze`, `config_update`, `exchange_start`, `market_cancel`, etc.).

### Publishing
- Released via RubyGems Trusted Publishing (OIDC). No long-lived API token stored in the repo.
- Tag prefix: `rb-v*`.

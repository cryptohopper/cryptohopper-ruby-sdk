# frozen_string_literal: true

RSpec.describe Cryptohopper::Client do
  let(:api_key) { "ch_test" }

  def build_client(**opts)
    described_class.new(api_key: api_key, max_retries: 0, **opts)
  end

  describe "#initialize" do
    it "rejects an empty api_key" do
      expect { described_class.new(api_key: "") }.to raise_error(ArgumentError, /api_key/)
    end

    it "rejects a nil api_key" do
      expect { described_class.new(api_key: nil) }.to raise_error(ArgumentError)
    end

    it "strips trailing slash from base_url" do
      c = described_class.new(api_key: api_key, base_url: "https://api-staging.cryptohopper.com/v1/")
      expect(c.base_url).to eq("https://api-staging.cryptohopper.com/v1")
    end
  end

  describe "transport" do
    it "sends Authorization + User-Agent headers and unwraps {data}" do
      stub_request(:get, "https://api.cryptohopper.com/v1/user/get")
        .with(
          headers: {
            "Authorization" => "Bearer ch_test",
            "Accept" => "application/json",
            "User-Agent" => "cryptohopper-sdk-ruby/#{Cryptohopper::VERSION}"
          }
        )
        .to_return(status: 200, body: '{"data":{"hello":"world"}}',
                   headers: { "Content-Type" => "application/json" })

      out = build_client.send(:_request, "GET", "/user/get")
      expect(out).to eq({ "hello" => "world" })
    end

    it "sends x-api-app-key when app_key is provided" do
      stub_request(:get, "https://api.cryptohopper.com/v1/user/get")
        .with(headers: { "x-api-app-key" => "client_123" })
        .to_return(status: 200, body: '{"data":{}}')

      build_client(app_key: "client_123").send(:_request, "GET", "/user/get")
    end

    it "attaches JSON body on POST" do
      stub_request(:post, "https://api.cryptohopper.com/v1/x")
        .with(
          body: '{"foo":1}',
          headers: { "Content-Type" => "application/json" }
        )
        .to_return(status: 200, body: '{"data":{"ok":true}}')

      out = build_client.send(:_request, "POST", "/x", body: { foo: 1 })
      expect(out).to eq({ "ok" => true })
    end

    it "serialises query params and skips nils" do
      stub_request(:get, "https://api.cryptohopper.com/v1/exchange/ticker")
        .with(query: { exchange: "binance", market: "BTC/USDT" })
        .to_return(status: 200, body: '{"data":{}}')

      build_client.send(
        :_request, "GET", "/exchange/ticker",
        params: { exchange: "binance", market: "BTC/USDT", skip: nil }
      )
    end

    it "maps the Cryptohopper error envelope to a typed exception" do
      stub_request(:get, "https://api.cryptohopper.com/v1/x")
        .to_return(
          status: 403,
          body: '{"status":403,"code":0,"error":1,"message":"no access","ip_address":"1.2.3.4"}'
        )

      expect { build_client.send(:_request, "GET", "/x") }.to raise_error do |err|
        expect(err).to be_a(Cryptohopper::Error)
        expect(err.code).to eq("FORBIDDEN")
        expect(err.status).to eq(403)
        expect(err.ip_address).to eq("1.2.3.4")
        expect(err.message).to eq("no access")
      end
    end

    it "retries on 429 honouring Retry-After, then succeeds" do
      call_count = 0
      stub_request(:get, "https://api.cryptohopper.com/v1/x").to_return do
        call_count += 1
        if call_count == 1
          {
            status: 429,
            headers: { "Retry-After" => "0" },
            body: '{"status":429,"code":0,"error":1,"message":"slow"}'
          }
        else
          { status: 200, body: '{"data":{"ok":true}}' }
        end
      end

      c = described_class.new(api_key: api_key, max_retries: 2)
      out = c.send(:_request, "GET", "/x")
      expect(out).to eq({ "ok" => true })
      expect(call_count).to eq(2)
    end

    it "gives up after max_retries on persistent 429" do
      stub_request(:get, "https://api.cryptohopper.com/v1/x").to_return(
        status: 429,
        headers: { "Retry-After" => "0" },
        body: '{"status":429,"code":0,"error":1,"message":"slow"}'
      )

      c = described_class.new(api_key: api_key, max_retries: 2)
      expect { c.send(:_request, "GET", "/x") }.to raise_error do |err|
        expect(err.code).to eq("RATE_LIMITED")
      end
    end

    it "falls back to SERVER_ERROR on non-JSON 5xx" do
      stub_request(:get, "https://api.cryptohopper.com/v1/x")
        .to_return(status: 500, body: "upstream crashed")

      expect { build_client.send(:_request, "GET", "/x") }.to raise_error do |err|
        expect(err.code).to eq("SERVER_ERROR")
        expect(err.status).to eq(500)
      end
    end

    it "maps network failures to NETWORK_ERROR" do
      stub_request(:get, "https://api.cryptohopper.com/v1/x")
        .to_raise(SocketError.new("getaddrinfo: nodename nor servname provided"))

      expect { build_client.send(:_request, "GET", "/x") }.to raise_error do |err|
        expect(err.code).to eq("NETWORK_ERROR")
        expect(err.status).to eq(0)
      end
    end

    it "maps Net::ReadTimeout (idle) to TIMEOUT" do
      stub_request(:get, "https://api.cryptohopper.com/v1/x")
        .to_raise(Net::ReadTimeout.new)

      expect { build_client.send(:_request, "GET", "/x") }.to raise_error do |err|
        expect(err.code).to eq("TIMEOUT")
        expect(err.status).to eq(0)
      end
    end

    it "maps Timeout::Error (total deadline) to TIMEOUT" do
      # Net::HTTP's read_timeout is per-read; a server that trickles bytes
      # faster than the timeout would otherwise hang indefinitely. The
      # transport wraps the request in Timeout.timeout to enforce a true
      # total deadline. Simulate the Timeout::Error path directly.
      stub_request(:get, "https://api.cryptohopper.com/v1/x")
        .to_raise(Timeout::Error.new("execution expired"))

      expect { build_client.send(:_request, "GET", "/x") }.to raise_error do |err|
        expect(err.code).to eq("TIMEOUT")
        expect(err.status).to eq(0)
      end
    end

    it "skips x-api-app-key header when app_key is an empty string" do
      stub_request(:get, "https://api.cryptohopper.com/v1/user/get")
        .with do |req|
          # WebMock's `with(headers:)` only checks presence; we want to
          # assert ABSENCE, so do it via a custom matcher block.
          !req.headers.key?("X-Api-App-Key")
        end
        .to_return(status: 200, body: '{"data":{}}')

      build_client(app_key: "").send(:_request, "GET", "/user/get")
    end
  end
end

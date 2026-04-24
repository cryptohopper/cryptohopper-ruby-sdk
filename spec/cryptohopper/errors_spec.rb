# frozen_string_literal: true

RSpec.describe Cryptohopper::Error do
  it "captures code, status, message, server_code, and ip_address" do
    err = described_class.new(
      code: "FORBIDDEN",
      message: "This action requires 'trade' permission scope.",
      status: 403,
      server_code: 42,
      ip_address: "203.0.113.42"
    )
    expect(err).to be_a(StandardError)
    expect(err.code).to eq("FORBIDDEN")
    expect(err.status).to eq(403)
    expect(err.server_code).to eq(42)
    expect(err.ip_address).to eq("203.0.113.42")
    expect(err.message).to eq("This action requires 'trade' permission scope.")
  end

  it "allows unknown string codes to pass through" do
    err = described_class.new(code: "SOMETHING_NEW", message: "weird", status: 418)
    expect(err.code).to eq("SOMETHING_NEW")
  end

  it "carries retry_after_ms when provided" do
    err = described_class.new(
      code: "RATE_LIMITED", message: "slow", status: 429, retry_after_ms: 4000
    )
    expect(err.retry_after_ms).to eq(4000)
  end
end

# frozen_string_literal: true

require_relative "lib/cryptohopper/version"

Gem::Specification.new do |spec|
  spec.name = "cryptohopper"
  spec.version = Cryptohopper::VERSION
  spec.authors = ["Cryptohopper"]
  spec.email = ["info@cryptohopper.com"]

  spec.summary = "Official Ruby SDK for the Cryptohopper API"
  spec.description = <<~DESC
    Ruby client for the Cryptohopper trading-bot platform API. OAuth2 bearer auth,
    auto-retry on 429, typed errors, stdlib-only transport (Net::HTTP). Covers all
    18 public API domains.
  DESC
  spec.homepage = "https://www.cryptohopper.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cryptohopper/cryptohopper-ruby-sdk"
  spec.metadata["changelog_uri"] = "https://github.com/cryptohopper/cryptohopper-ruby-sdk/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/cryptohopper/cryptohopper-ruby-sdk/issues"
  spec.metadata["documentation_uri"] = "https://api.cryptohopper.com/v1/docs"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["lib/**/*.rb", "LICENSE", "README.md", "CHANGELOG.md"]
  end
  spec.require_paths = ["lib"]
end

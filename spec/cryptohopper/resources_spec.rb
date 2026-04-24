# frozen_string_literal: true

RSpec.describe "resource path sanity" do
  let(:client) { Cryptohopper::Client.new(api_key: "ch_test", max_retries: 0) }

  def stub_empty(method, path, query: nil, body: nil)
    url = "https://api.cryptohopper.com/v1#{path}"
    stub = stub_request(method, url)
    stub = stub.with(query: query) if query
    stub = stub.with(body: body) if body
    stub.to_return(status: 200, body: '{"data":{}}')
  end

  describe "user" do
    it "get → GET /user/get" do
      stub_empty(:get, "/user/get")
      client.user.get
    end
  end

  describe "hoppers" do
    it "list → GET /hopper/list with exchange filter" do
      stub_empty(:get, "/hopper/list", query: { exchange: "binance" })
      client.hoppers.list(exchange: "binance")
    end

    it "get → GET /hopper/get?hopper_id=42" do
      stub_empty(:get, "/hopper/get", query: { hopper_id: "42" })
      client.hoppers.get(42)
    end

    it "buy → POST /hopper/buy with JSON body" do
      stub_empty(:post, "/hopper/buy",
                 body: '{"hopper_id":42,"market":"BTC/USDT","amount":"0.001"}')
      client.hoppers.buy(hopper_id: 42, market: "BTC/USDT", amount: "0.001")
    end

    it "config_update merges hopper_id into body" do
      stub_empty(:post, "/hopper/configupdate",
                 body: '{"hopper_id":7,"strategy_id":99}')
      client.hoppers.config_update(7, strategy_id: 99)
    end

    it "panic → POST /hopper/panic" do
      stub_empty(:post, "/hopper/panic", body: '{"hopper_id":5}')
      client.hoppers.panic(5)
    end
  end

  describe "exchange" do
    it "ticker → GET /exchange/ticker" do
      stub_empty(:get, "/exchange/ticker",
                 query: { exchange: "binance", market: "BTC/USDT" })
      client.exchange.ticker(exchange: "binance", market: "BTC/USDT")
    end

    it "forex_rates → GET /exchange/forex-rates (hyphenated path)" do
      stub_empty(:get, "/exchange/forex-rates")
      client.exchange.forex_rates
    end
  end

  describe "strategy" do
    it "list → GET /strategy/strategies (server uses plural)" do
      stub_empty(:get, "/strategy/strategies")
      client.strategy.list
    end

    it "update → POST /strategy/edit (server uses 'edit')" do
      stub_empty(:post, "/strategy/edit", body: '{"strategy_id":5,"name":"r"}')
      client.strategy.update(5, name: "r")
    end
  end

  describe "backtest" do
    it "create → POST /backtest/new" do
      stub_empty(:post, "/backtest/new", body: '{"hopper_id":42}')
      client.backtest.create(hopper_id: 42)
    end

    it "limits → GET /backtest/limits" do
      stub_empty(:get, "/backtest/limits")
      client.backtest.limits
    end
  end

  describe "market" do
    it "items → GET /market/marketitems" do
      stub_empty(:get, "/market/marketitems", query: { type: "strategy" })
      client.market.items(type: "strategy")
    end
  end

  describe "signals (provider analytics)" do
    it "chart_data → GET /signals/chartdata" do
      stub_empty(:get, "/signals/chartdata")
      client.signals.chart_data
    end
  end

  describe "arbitrage" do
    it "market_cancel → POST /arbitrage/market-cancel (hyphenated)" do
      stub_empty(:post, "/arbitrage/market-cancel", body: "{}")
      client.arbitrage.market_cancel
    end

    it "delete_backlog → POST /arbitrage/delete-backlog with backlog_id" do
      stub_empty(:post, "/arbitrage/delete-backlog", body: '{"backlog_id":7}')
      client.arbitrage.delete_backlog(7)
    end
  end

  describe "marketmaker" do
    it "set_market_trend → POST /marketmaker/set-market-trend" do
      stub_empty(:post, "/marketmaker/set-market-trend",
                 body: '{"hopper_id":1,"trend":"bull"}')
      client.marketmaker.set_market_trend(hopper_id: 1, trend: "bull")
    end
  end

  describe "template" do
    it "save → POST /template/save-template" do
      stub_empty(:post, "/template/save-template", body: '{"name":"t"}')
      client.template.save(name: "t")
    end

    it "load → POST /template/load with both ids" do
      stub_empty(:post, "/template/load",
                 body: '{"template_id":3,"hopper_id":5}')
      client.template.load(3, 5)
    end
  end

  describe "ai" do
    it "available_models → GET /ai/availablemodels" do
      stub_empty(:get, "/ai/availablemodels")
      client.ai.available_models
    end

    it "llm_analyze → POST /ai/doaillmanalyze" do
      stub_empty(:post, "/ai/doaillmanalyze", body: '{"strategy_id":42}')
      client.ai.llm_analyze(strategy_id: 42)
    end
  end

  describe "platform" do
    it "search_documentation → GET /platform/searchdocumentation?q=rsi" do
      stub_empty(:get, "/platform/searchdocumentation", query: { q: "rsi" })
      client.platform.search_documentation("rsi")
    end

    it "bot_types → GET /platform/bottypes" do
      stub_empty(:get, "/platform/bottypes")
      client.platform.bot_types
    end
  end

  describe "chart" do
    it "share_save → POST /chart/share-save (hyphenated)" do
      stub_empty(:post, "/chart/share-save", body: '{"title":"BTC"}')
      client.chart.share_save(title: "BTC")
    end
  end

  describe "subscription" do
    it "plans → GET /subscription/plans" do
      stub_empty(:get, "/subscription/plans")
      client.subscription.plans
    end

    it "stop_subscription posts empty body" do
      stub_empty(:post, "/subscription/stopsubscription", body: "{}")
      client.subscription.stop_subscription
    end
  end

  describe "social" do
    it "get_profile sends alias" do
      stub_empty(:get, "/social/getprofile", query: { alias: "pim" })
      client.social.get_profile("pim")
    end

    it "create_post → POST /social/post (bare `post`)" do
      stub_empty(:post, "/social/post", body: '{"content":"hi"}')
      client.social.create_post(content: "hi")
    end

    it "get_conversation → GET /social/loadconversation" do
      stub_empty(:get, "/social/loadconversation",
                 query: { conversation_id: "42" })
      client.social.get_conversation(42)
    end

    it "like posts post_id" do
      stub_empty(:post, "/social/like", body: '{"post_id":99}')
      client.social.like(99)
    end
  end

  describe "tournaments" do
    it "list → GET /tournaments/gettournaments" do
      stub_empty(:get, "/tournaments/gettournaments")
      client.tournaments.list
    end

    it "tournament_leaderboard → GET /tournaments/leaderboard_tournament" do
      stub_empty(:get, "/tournaments/leaderboard_tournament",
                 query: { tournament_id: "7" })
      client.tournaments.tournament_leaderboard(7)
    end

    it "join merges tournament_id into body" do
      stub_empty(:post, "/tournaments/join",
                 body: '{"tournament_id":5,"team":"alpha"}')
      client.tournaments.join(5, team: "alpha")
    end
  end

  describe "webhooks" do
    it "create → POST /api/webhook_create" do
      stub_empty(:post, "/api/webhook_create",
                 body: '{"url":"https://e.com"}')
      client.webhooks.create(url: "https://e.com")
    end

    it "delete → POST /api/webhook_delete with webhook_id" do
      stub_empty(:post, "/api/webhook_delete", body: '{"webhook_id":42}')
      client.webhooks.delete(42)
    end
  end

  describe "app" do
    it "in_app_purchase → POST /app/in_app_purchase (underscored)" do
      stub_empty(:post, "/app/in_app_purchase", body: '{"receipt":"abc"}')
      client.app.in_app_purchase(receipt: "abc")
    end
  end
end

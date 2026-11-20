extends TestCase

var sim: Simulation


func before_each() -> void:
	sim = TestWorld.new_sim()


func test_world_demand_calibrated_to_supply() -> void:
	var st: MarketState = MarketState.of(sim.world)
	for kid in sim.content.commodity_ids:
		var prod: float = 0.0
		var cons: float = 0.0
		for cid in sim.content.country_ids:
			prod += float(st.markets[cid][kid]["base_prod"])
			cons += float(st.markets[cid][kid]["base_cons"])
		assert_near(cons / prod, 1.0, 1e-6, kid)


func test_warmup_creates_price_dispersion_and_history() -> void:
	var lo: float = MarketQueries.price(sim.world, "BRA", "soybeans")
	var hi: float = MarketQueries.price(sim.world, "CHN", "soybeans")
	assert_true(hi > lo * 1.05, "Nước nhập khẩu phải đắt hơn nước xuất khẩu (%f vs %f)" % [hi, lo])
	assert_true(MarketQueries.history(sim.world, "VNM", "coffee").size() > 20)


func test_prices_stay_bounded_over_ten_years() -> void:
	sim.step_days(3650)
	for kid in sim.content.commodity_ids:
		var ref: float = sim.content.commodity(kid).base_price
		for cid in sim.content.country_ids:
			var p: float = MarketQueries.price(sim.world, cid, kid)
			assert_between(p / ref, 0.4, 2.5, "%s/%s" % [cid, kid])
		assert_between(MarketQueries.world_price(sim.world, kid) / ref, 0.6, 1.6, "world " + kid)


func test_buy_raises_price_and_sell_lowers() -> void:
	var p0: float = MarketQueries.price(sim.world, "VNM", "coffee")
	var q: int = Quantity.from_units(20_000)
	MarketService.execute(sim.world, sim.content, "VNM", "coffee", q, true)
	var p1: float = MarketQueries.price(sim.world, "VNM", "coffee")
	assert_true(p1 > p0)
	MarketService.execute(sim.world, sim.content, "VNM", "coffee", q, false)
	assert_true(MarketQueries.price(sim.world, "VNM", "coffee") < p1)


func test_quote_slippage_increases_with_size() -> void:
	var small: Dictionary = MarketQueries.quote(sim.world, sim.content, "VNM", "coffee", Quantity.from_units(100), true)
	var big: Dictionary = MarketQueries.quote(sim.world, sim.content, "VNM", "coffee", Quantity.from_units(50_000), true)
	assert_true(int(big["unit_price"]) > int(small["unit_price"]))
	var sell: Dictionary = MarketQueries.quote(sim.world, sim.content, "VNM", "coffee", Quantity.from_units(100), false)
	assert_true(int(sell["unit_price"]) < int(small["unit_price"]))


func test_quote_rejects_order_larger_than_supply() -> void:
	var q: Dictionary = MarketQueries.quote(sim.world, sim.content, "VNM", "coffee", Quantity.from_units(100_000_000), true)
	assert_false(bool(q["ok"]))
	assert_eq(q["error_key"], "ERR_MARKET_SUPPLY")

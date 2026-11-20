extends TestCase

var sim: Simulation
var co: String


func before_each() -> void:
	sim = TestWorld.new_sim()
	co = sim.world.player_company_id


func test_buy_requires_warehouse() -> void:
	assert_err(sim.submit(BuyCommand.create(co, "BRA", "coffee", Quantity.from_units(10))), "ERR_NO_WAREHOUSE")


func test_buy_moves_cash_to_inventory() -> void:
	var cash0: int = FinanceQueries.cash(sim.world, co)
	var q: int = Quantity.from_units(500)
	var r: Result = sim.submit(BuyCommand.create(co, "VNM", "coffee", q))
	assert_ok(r)
	var wh: String = InventoryQueries.warehouse_in(sim.world, co, "VNM")
	assert_eq(InventoryQueries.available(sim.world, wh, "coffee"), q)
	var paid: int = cash0 - FinanceQueries.cash(sim.world, co)
	assert_eq(InventoryQueries.cost_of(sim.world, wh, "coffee"), paid)
	assert_eq(TestWorld.check_invariants(sim), [] as Array[String])


func test_buy_rejected_without_cash() -> void:
	var r: Result = sim.submit(BuyCommand.create(co, "VNM", "copper", Quantity.from_units(2_000)))
	assert_err(r, "ERR_NOT_ENOUGH_CASH")


func test_sell_creates_receivable_then_collects() -> void:
	var wh: String = InventoryQueries.warehouse_in(sim.world, co, "VNM")
	sim.submit(BuyCommand.create(co, "VNM", "rice", Quantity.from_units(2000)))
	var cash_after_buy: int = FinanceQueries.cash(sim.world, co)
	assert_ok(sim.submit(SellCommand.create(co, wh, "rice", Quantity.from_units(2000))))
	var ar: int = TradeQueries.total_receivables(sim.world, co)
	assert_true(ar > 0)
	assert_eq(FinanceQueries.cash(sim.world, co), cash_after_buy, "Bán chưa thu tiền ngay")
	assert_eq(TestWorld.check_invariants(sim), [] as Array[String])
	sim.step_days(31)
	assert_eq(TradeQueries.total_receivables(sim.world, co), 0)
	assert_true(FinanceQueries.cash(sim.world, co) > cash_after_buy)


func test_sell_more_than_stock_rejected() -> void:
	var wh: String = InventoryQueries.warehouse_in(sim.world, co, "VNM")
	assert_err(sim.submit(SellCommand.create(co, wh, "rice", Quantity.from_units(1))), "ERR_NOT_ENOUGH_STOCK")

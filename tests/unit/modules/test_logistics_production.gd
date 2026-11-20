extends TestCase

var sim: Simulation
var co: String
var vn: String


func before_each() -> void:
	sim = TestWorld.new_sim()
	co = sim.world.player_company_id
	vn = InventoryQueries.warehouse_in(sim.world, co, "VNM")


func test_shipping_quote_reasonable() -> void:
	var q: Dictionary = LogisticsQueries.quote(sim.content, "VNM", "DEU", Quantity.from_units(1000))
	assert_between(float(q["distance_km"]), 10_000.0, 20_000.0)
	assert_between(float(q["days"]), 15.0, 35.0)
	assert_true(int(q["freight"]) > 0)


func test_shipment_moves_goods_and_capitalizes_freight() -> void:
	sim.submit(OpenWarehouseCommand.create(co, "DEU"))
	var de: String = InventoryQueries.warehouse_in(sim.world, co, "DEU")
	sim.submit(BuyCommand.create(co, "VNM", "coffee", Quantity.from_units(300)))
	var goods_cost: int = InventoryQueries.cost_of(sim.world, vn, "coffee")
	var r: Result = sim.submit(ShipCommand.create(co, vn, de, "coffee", Quantity.from_units(300)))
	assert_ok(r)
	var freight: int = int(r.value["freight"])
	assert_eq(InventoryQueries.available(sim.world, vn, "coffee"), 0)
	assert_eq(LogisticsQueries.shipments_of(sim.world, co).size(), 1)
	assert_eq(TestWorld.check_invariants(sim), [] as Array[String])
	sim.step_days(int(r.value["days"]) + 8)
	assert_eq(LogisticsQueries.shipments_of(sim.world, co).size(), 0)
	assert_eq(InventoryQueries.available(sim.world, de, "coffee"), Quantity.from_units(300))
	assert_eq(InventoryQueries.cost_of(sim.world, de, "coffee"), goods_cost + freight)
	assert_eq(TestWorld.check_invariants(sim), [] as Array[String])


func test_factory_build_and_produce() -> void:
	assert_ok(sim.submit(BuildFactoryCommand.create(co, vn, "coffee_roastery")))
	var f: Dictionary = ProductionQueries.factories_of(sim.world, co)[0]
	assert_eq(f["status"], ProductionQueries.STATUS_BUILDING)
	sim.submit(BuyCommand.create(co, "VNM", "coffee", Quantity.from_units(200)))
	var def: FacilityDef = sim.content.facility("coffee_roastery")
	sim.step_days(def.build_days + 5)
	f = ProductionQueries.factory(sim.world, str(f["id"]))
	assert_eq(int(f["total_output"]), def.capacity_per_day * 5)
	assert_eq(InventoryQueries.available(sim.world, vn, "roasted_coffee"), def.capacity_per_day * 5)
	assert_eq(TestWorld.check_invariants(sim), [] as Array[String])


func test_factory_stops_without_input() -> void:
	sim.submit(BuildFactoryCommand.create(co, vn, "coffee_roastery"))
	sim.step_days(sim.content.facility("coffee_roastery").build_days + 2)
	var f: Dictionary = ProductionQueries.factories_of(sim.world, co)[0]
	assert_eq(f["status"], ProductionQueries.STATUS_NO_INPUT)
	sim.submit(SetFactoryActiveCommand.create(co, str(f["id"]), false))
	assert_eq(ProductionQueries.factory(sim.world, str(f["id"]))["status"], ProductionQueries.STATUS_PAUSED)


func test_depreciation_and_overhead_monthly() -> void:
	sim.submit(BuildFactoryCommand.create(co, vn, "coffee_roastery"))
	sim.step_days(120)
	var bs: Dictionary = FinanceQueries.balance_sheet(sim.world, sim.content, co)
	assert_true(int(bs["assets"][Accounts.ACCUM_DEPRECIATION]) < 0)
	assert_eq(TestWorld.check_invariants(sim), [] as Array[String])

extends TestCase
## Chạy nhiều năm với hoạt động của người chơi, kiểm tra bất biến mỗi tháng.


func test_five_years_with_activity_keeps_invariants() -> void:
	var sim: Simulation = TestWorld.new_sim(777)
	var w: WorldState = sim.world
	var co: String = w.player_company_id
	var vn: String = InventoryQueries.warehouse_in(w, co, "VNM")
	sim.submit(OpenWarehouseCommand.create(co, "SAU"))
	var sa: String = InventoryQueries.warehouse_in(w, co, "SAU")
	sim.submit(BuildFactoryCommand.create(co, vn, "coffee_roastery"))
	for month in 60:
		sim.submit(BuyCommand.create(co, "VNM", "coffee", Quantity.from_units(400)))
		sim.submit(BuyCommand.create(co, "VNM", "rice", Quantity.from_units(1000)))
		var rice: int = InventoryQueries.available(w, vn, "rice")
		if rice > 0:
			sim.submit(ShipCommand.create(co, vn, sa, "rice", rice))
		var sa_rice: int = InventoryQueries.available(w, sa, "rice")
		if sa_rice > 0:
			sim.submit(SellCommand.create(co, sa, "rice", sa_rice))
		var roasted: int = InventoryQueries.available(w, vn, "roasted_coffee")
		if roasted > 0:
			sim.submit(SellCommand.create(co, vn, "roasted_coffee", roasted))
		sim.step_days(30)
		var errs: Array[String] = TestWorld.check_invariants(sim)
		if not errs.is_empty():
			fail("Tháng %d: %s" % [month, errs])
			return
	assert_eq(FinanceQueries.reports(w, co).size(), 59)
	assert_true(FinanceQueries.all_time(w, sim.content, co)["revenue"] > 0)

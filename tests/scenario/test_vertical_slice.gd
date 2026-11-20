extends TestCase
## Chuỗi mẫu của M2 (từ hồ sơ concept):
## mua nguyên liệu -> vận chuyển -> sản xuất -> bán -> thu tiền -> báo cáo.


func test_coffee_value_chain_end_to_end() -> void:
	var sim: Simulation = TestWorld.new_sim(2027)
	var w: WorldState = sim.world
	var co: String = w.player_company_id
	var vn: String = InventoryQueries.warehouse_in(w, co, "VNM")

	# 1. Mở kho ở Đức và xây xưởng rang xay tại đó.
	assert_ok(sim.submit(OpenWarehouseCommand.create(co, "DEU")))
	var de: String = InventoryQueries.warehouse_in(w, co, "DEU")
	assert_ok(sim.submit(BuildFactoryCommand.create(co, de, "coffee_roastery")))

	# 2. Vay thêm vốn lưu động rồi mua 1.000 t cà phê nhân ở Việt Nam.
	assert_ok(sim.submit(TakeLoanCommand.create(co, Money.from_units(2_000_000))))
	var buy: Result = sim.submit(BuyCommand.create(co, "VNM", "coffee", Quantity.from_units(1000)))
	assert_ok(buy)
	var purchase_cost: int = int(buy.value["total"])

	# 3. Chở sang Hamburg.
	var ship: Result = sim.submit(ShipCommand.create(co, vn, de, "coffee", Quantity.from_units(1000)))
	assert_ok(ship)
	var freight: int = int(ship.value["freight"])

	# 4. Chờ hàng đến + xưởng xây xong + chạy sản xuất.
	var roastery: FacilityDef = sim.content.facility("coffee_roastery")
	sim.step_days(roastery.build_days + 40)
	assert_eq(InventoryQueries.available(w, vn, "coffee"), 0)
	var roasted: int = InventoryQueries.available(w, de, "roasted_coffee")
	assert_true(roasted > Quantity.from_units(300), "Đã rang được %s" % Quantity.format(roasted))
	assert_eq(TestWorld.check_invariants(sim), [] as Array[String])

	# Giá vốn hàng rang = nguyên liệu (mua + cước) đã dùng + chi phí biến đổi.
	var beans_left: int = InventoryQueries.available(w, de, "coffee")
	var beans_used: int = Quantity.from_units(1000) - beans_left
	var beans_cost_used: int = purchase_cost + freight - InventoryQueries.cost_of(w, de, "coffee")
	var expected_cost: int = beans_cost_used + UnitPrice.total(roastery.variable_cost_per_unit, roasted)
	assert_near(float(InventoryQueries.cost_of(w, de, "roasted_coffee")), float(expected_cost), 2.0 * float(roasted / Quantity.SCALE + 10))
	assert_true(beans_used > 0)

	# 5. Bán toàn bộ cà phê rang ở Đức.
	var cash_before_sale: int = FinanceQueries.cash(w, co)
	var sale_cost: int = InventoryQueries.cost_of(w, de, "roasted_coffee")
	var sell: Result = sim.submit(SellCommand.create(co, de, "roasted_coffee", roasted))
	assert_ok(sell)
	var revenue: int = int(sell.value["total"])
	assert_true(revenue > sale_cost, "Chuỗi giá trị phải có lãi gộp (%s vs %s)" % [Money.format(revenue), Money.format(sale_cost)])
	assert_eq(FinanceQueries.cash(w, co), cash_before_sale, "Tiền chưa về ngay khi bán")

	# 6. Thu tiền sau 30 ngày.
	sim.step_days(31)
	assert_eq(TradeQueries.total_receivables(w, co), 0)

	# 7. Báo cáo: doanh thu/giá vốn trong sổ cái khớp với giao dịch.
	var all_time: Dictionary = FinanceQueries.all_time(w, sim.content, co)
	assert_eq(int(all_time["revenue"]), revenue)
	assert_eq(int(all_time["cogs"]), sale_cost)
	var reports: Array = FinanceQueries.reports(w, co)
	assert_true(reports.size() >= 3)
	var sum_revenue: int = 0
	for r: Dictionary in reports:
		sum_revenue += int(r["revenue"])
	sum_revenue += int(FinanceQueries.month_to_date(w, sim.content, co)["revenue"])
	assert_eq(sum_revenue, revenue, "Tổng doanh thu các kỳ = doanh thu lũy kế")
	assert_eq(TestWorld.check_invariants(sim), [] as Array[String])

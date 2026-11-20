extends TestCase

var sim: Simulation
var co: String
var wh: String


func before_each() -> void:
	sim = TestWorld.new_sim()
	co = sim.world.player_company_id
	wh = InventoryQueries.warehouse_in(sim.world, co, "VNM")


func test_start_warehouse_exists() -> void:
	assert_ne(wh, "")
	assert_eq(InventoryQueries.warehouses_of(sim.world, co).size(), 1)


func test_weighted_average_cost() -> void:
	InventoryService.add(sim.world, wh, "coffee", Quantity.from_units(100), Money.from_units(400_000))
	InventoryService.add(sim.world, wh, "coffee", Quantity.from_units(100), Money.from_units(500_000))
	assert_eq(InventoryQueries.avg_cost(sim.world, wh, "coffee"), UnitPrice.from_float(4500.0))
	var cost: int = InventoryService.remove(sim.world, wh, "coffee", Quantity.from_units(50))
	assert_eq(cost, Money.from_units(225_000))
	# Xuất hết: lấy đúng phần cost còn lại, không lệch làm tròn.
	var rest: int = InventoryService.remove(sim.world, wh, "coffee", Quantity.from_units(150))
	assert_eq(cost + rest, Money.from_units(900_000))
	assert_eq(InventoryQueries.available(sim.world, wh, "coffee"), 0)


func test_open_warehouse_command() -> void:
	assert_err(sim.submit(OpenWarehouseCommand.create(co, "VNM")), "ERR_WAREHOUSE_EXISTS")
	assert_ok(sim.submit(OpenWarehouseCommand.create(co, "DEU")))
	assert_ne(InventoryQueries.warehouse_in(sim.world, co, "DEU"), "")
	assert_eq(FinanceQueries.cash(sim.world, co), Money.from_units(5_000_000 - 150_000))


func test_monthly_storage_cost() -> void:
	InventoryService.add(sim.world, wh, "rice", Quantity.from_units(1000), 0)
	sim.step_days(31)
	var rep: Dictionary = FinanceQueries.reports(sim.world, co)[0]
	# thuê 12,000 + 1,000 t × 1.5
	assert_eq(int(rep["lines"][Accounts.STORAGE_EXPENSE]), Money.from_units(13_500))

extends TestCase
## Lưu/tải giữa chừng phải cho kết quả GIỐNG HỆT chạy liên tục (tính tất định).


func _play_some(sim: Simulation) -> void:
	var co: String = sim.world.player_company_id
	var vn: String = InventoryQueries.warehouse_in(sim.world, co, "VNM")
	sim.submit(OpenWarehouseCommand.create(co, "CHN"))
	sim.submit(BuyCommand.create(co, "VNM", "rice", Quantity.from_units(5000)))
	sim.submit(ShipCommand.create(co, vn, InventoryQueries.warehouse_in(sim.world, co, "CHN"), "rice", Quantity.from_units(4000)))
	sim.submit(BuildFactoryCommand.create(co, vn, "coffee_roastery"))
	sim.submit(BuyCommand.create(co, "VNM", "coffee", Quantity.from_units(300)))
	sim.submit(TakeLoanCommand.create(co, Money.from_units(500_000)))


func test_save_load_midway_is_deterministic() -> void:
	var a: Simulation = TestWorld.new_sim(99)
	_play_some(a)
	a.step_days(200)

	var b: Simulation = TestWorld.new_sim(99)
	_play_some(b)
	b.step_days(80)
	var text: String = SaveService.encode(SaveService.to_save(b))
	var c := Simulation.create_from_content(TestWorld.content())
	var decoded: Result = SaveService.decode(text)
	assert_ok(decoded)
	c.load_save_dict(decoded.value["data"])
	c.step_days(120)

	assert_eq(TestWorld.state_hash(c), TestWorld.state_hash(a))
	assert_eq(TestWorld.check_invariants(c), [] as Array[String])


func test_same_seed_same_world() -> void:
	var a: Simulation = TestWorld.new_sim(5)
	var b: Simulation = TestWorld.new_sim(5)
	a.step_days(60)
	b.step_days(60)
	assert_eq(TestWorld.state_hash(a), TestWorld.state_hash(b))
	var c: Simulation = TestWorld.new_sim(6)
	c.step_days(60)
	assert_ne(TestWorld.state_hash(a), TestWorld.state_hash(c))


func test_save_file_roundtrip() -> void:
	var a: Simulation = TestWorld.new_sim(1)
	_play_some(a)
	a.step_days(10)
	var path: String = "user://test_saves/roundtrip.sav"
	assert_ok(SaveService.save_to_file(a, path))
	assert_eq(int(SaveService.read_header(path)["save_version"]), SaveFormat.CURRENT_VERSION)
	var b := Simulation.create_from_content(TestWorld.content())
	assert_ok(SaveService.load_from_file(b, path))
	assert_eq(TestWorld.state_hash(b), TestWorld.state_hash(a))
	DirAccess.remove_absolute(path)


class AddFieldMigration extends SaveMigration:
	func migrate(data: Dictionary) -> Dictionary:
		data["migrated"] = true
		return data


func test_migration_chain() -> void:
	var save: Dictionary = {"header": {"save_version": 0}, "data": {}}
	var r: Result = SaveMigrations.migrate(save, {0: AddFieldMigration.new()}, 1)
	assert_ok(r)
	assert_true(bool(r.value["data"]["migrated"]))
	assert_err(SaveMigrations.migrate(save, {}, 1), "ERR_SAVE_NO_MIGRATION")
	assert_err(SaveMigrations.migrate({"header": {"save_version": 99}, "data": {}}), "ERR_SAVE_TOO_NEW")

extends TestCase
## Kiểm tra động cơ mô phỏng bằng module giả.


class CounterState extends ModuleState:
	var daily: int = 0
	var weekly: int = 0
	var monthly: int = 0

	func to_dict() -> Dictionary:
		return {"daily": daily, "weekly": weekly, "monthly": monthly}

	func from_dict(d: Dictionary) -> void:
		daily = SaveUtil.i(d, "daily")
		weekly = SaveUtil.i(d, "weekly")
		monthly = SaveUtil.i(d, "monthly")


class CountSystem extends SimSystem:
	var freq: SimSystem.Frequency
	func _init(f: SimSystem.Frequency) -> void:
		freq = f
	func get_frequency() -> SimSystem.Frequency:
		return freq
	func run(world: WorldState, _ctx: TickContext) -> void:
		var st: CounterState = world.get_state("counter")
		match freq:
			SimSystem.Frequency.DAILY: st.daily += 1
			SimSystem.Frequency.WEEKLY: st.weekly += 1
			SimSystem.Frequency.MONTHLY: st.monthly += 1


class AddCommand extends SimCommand:
	var amount: int = 0
	func get_type() -> String:
		return "counter.add"
	func validate(_world: WorldState, _ctx: TickContext) -> Result:
		return Result.success() if amount > 0 else Result.fail("ERR_AMOUNT_POSITIVE")
	func apply(world: WorldState, ctx: TickContext) -> void:
		(world.get_state("counter") as CounterState).daily += amount
		ctx.emit("counter.added", {"amount": amount})


class CounterModule extends SimModule:
	func get_id() -> String:
		return "counter"
	func get_dependencies() -> Array[String]:
		return ["base"]
	func register(ctx: ModuleContext) -> void:
		ctx.register_state(CounterState)
		ctx.register_system(CountSystem.new(SimSystem.Frequency.MONTHLY))
		ctx.register_system(CountSystem.new(SimSystem.Frequency.DAILY))
		ctx.register_system(CountSystem.new(SimSystem.Frequency.WEEKLY))
		ctx.register_command("counter.add", AddCommand)


class BaseModule extends SimModule:
	func get_id() -> String:
		return "base"


class CycleA extends SimModule:
	func get_id() -> String:
		return "a"
	func get_dependencies() -> Array[String]:
		return ["b"]


class CycleB extends SimModule:
	func get_id() -> String:
		return "b"
	func get_dependencies() -> Array[String]:
		return ["a"]


func _make_sim() -> Simulation:
	var mods: Array[SimModule] = [CounterModule.new(), BaseModule.new()]
	var sim := Simulation.create(TestWorld.content(), mods)
	sim.world = WorldState.new()
	sim.world.day = GameDate.from_ymd(2027, 1, 1)
	sim._create_states()
	return sim


func test_modules_sorted_by_dependencies() -> void:
	var sim := _make_sim()
	assert_eq(sim.modules[0].get_id(), "base")
	assert_eq(sim.modules[1].get_id(), "counter")


func test_cycle_detected() -> void:
	var mods: Array[SimModule] = [CycleA.new(), CycleB.new()]
	assert_true(ModuleRegistry.find_dependency_error(mods).begins_with("cycle:"))
	var missing: Array[SimModule] = [CounterModule.new()]
	assert_true(ModuleRegistry.find_dependency_error(missing).begins_with("missing:"))


func test_system_frequencies_over_one_year() -> void:
	var sim := _make_sim()
	sim.step_days(365)  # 2027 không nhuận
	var st: CounterState = sim.world.get_state("counter")
	assert_eq(st.daily, 365)
	assert_eq(st.weekly, 52)
	assert_eq(st.monthly, 12)
	assert_eq(sim.world.day, GameDate.from_ymd(2028, 1, 1))


func test_systems_ordered_by_phase() -> void:
	var sim := _make_sim()
	var last: int = -1
	for s in sim.systems():
		assert_true(s.get_phase() >= last)
		last = s.get_phase()


func test_command_validate_apply_and_events() -> void:
	var sim := _make_sim()
	var bad := AddCommand.new()
	assert_err(sim.submit(bad), "ERR_AMOUNT_POSITIVE")
	var cmd := AddCommand.new()
	cmd.amount = 5
	assert_ok(sim.submit(cmd))
	assert_eq((sim.world.get_state("counter") as CounterState).daily, 5)
	var events: Array[SimEvent] = sim.drain_events()
	assert_eq(events.size(), 1)
	assert_eq(events[0].type, "counter.added")
	assert_eq(sim.drain_events().size(), 0)
	assert_eq(sim.command_log.size(), 1)


func test_make_command_from_registry() -> void:
	var sim := _make_sim()
	assert_true(sim.has_command_type("counter.add"))
	assert_eq(sim.make_command("nope", "", {}), null)


func test_new_id_is_sequential() -> void:
	var w := WorldState.new()
	assert_eq(w.new_id("co"), "co_000001")
	assert_eq(w.new_id("co"), "co_000002")
	assert_eq(w.new_id("wh"), "wh_000001")

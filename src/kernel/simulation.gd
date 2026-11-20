class_name Simulation
extends RefCounted
## Động cơ mô phỏng: quản lý module, chạy tick theo phase, nhận command, gom domain event.
## Hoàn toàn không phụ thuộc Node — chạy được headless.

var content: ContentRegistry
var world: WorldState
var modules: Array[SimModule] = []
var ui_screens: Array[Dictionary] = []
## Lịch sử command đã áp dụng (phục vụ replay/debug).
var command_log: Array[Dictionary] = []

var _systems: Array[SimSystem] = []
var _state_scripts: Dictionary = {}     # module_id -> Script
var _command_types: Dictionary = {}     # type -> Script
var _event_handlers: Dictionary = {}    # event type -> Array[Callable]
var _queue: Array[SimCommand] = []
var _pending_events: Array[SimEvent] = []


## Tạo Simulation từ danh sách module (đã sắp xếp theo phụ thuộc trong ModuleRegistry).
static func create(p_content: ContentRegistry, p_modules: Array[SimModule]) -> Simulation:
	var sim := Simulation.new()
	sim.content = p_content
	sim.modules = ModuleRegistry.sort_by_dependencies(p_modules)
	for m in sim.modules:
		m.register(ModuleContext.new(sim, m.get_id()))
	sim.ui_screens.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["order"]) < int(b["order"]))
	sim.world = WorldState.new()
	return sim


## Tạo Simulation với các module khai báo trong data (modules.json).
static func create_from_content(p_content: ContentRegistry) -> Simulation:
	return create(p_content, ModuleRegistry.instantiate(p_content.modules))


func new_game(scenario_id: String = "default", seed_value: int = 12345) -> void:
	var scenario: Dictionary = content.scenarios.get(scenario_id, {})
	world = WorldState.new()
	world.world_seed = seed_value
	world.day = GameDate.parse(str(scenario.get("start_date", "2027-01-01")))
	_create_states()
	var ctx := TickContext.new(world.day, content, world.world_seed)
	for m in modules:
		m.on_new_game(world, ctx, scenario)
	_pending_events.append_array(ctx.events)
	command_log.clear()


func _create_states() -> void:
	for m in modules:
		var script: Script = _state_scripts.get(m.get_id())
		if script != null:
			world.set_state(m.get_id(), script.new() as RefCounted)


## Chạy một tick = một ngày.
func step() -> void:
	var ctx := TickContext.new(world.day, content, world.world_seed)
	var month_end: bool = GameDate.is_month_end(world.day)
	var week_end: bool = GameDate.is_week_end(world.day)
	# Command trong hàng đợi (AI/kịch bản) chạy ở phase COMMANDS.
	var queued: Array[SimCommand] = _queue.duplicate()
	_queue.clear()
	for cmd in queued:
		_execute(cmd, ctx)
	for system in _systems:
		match system.get_frequency():
			SimSystem.Frequency.WEEKLY:
				if not week_end:
					continue
			SimSystem.Frequency.MONTHLY:
				if not month_end:
					continue
		system.run(world, ctx)
	_dispatch(ctx.events)
	_pending_events.append_array(ctx.events)
	world.day += 1


func step_days(n: int) -> void:
	for i in n:
		step()


## Áp dụng command ngay (giữa hai tick) — dùng cho thao tác của người chơi.
func submit(cmd: SimCommand) -> Result:
	var ctx := TickContext.new(world.day, content, world.world_seed)
	var result: Result = _execute(cmd, ctx)
	_dispatch(ctx.events)
	_pending_events.append_array(ctx.events)
	return result


## Kiểm tra command mà không áp dụng (UI dùng để hiển thị lỗi trước).
func check(cmd: SimCommand) -> Result:
	return cmd.validate(world, TickContext.new(world.day, content, world.world_seed))


## Xếp hàng command để chạy ở phase COMMANDS của tick tiếp theo (AI, kịch bản).
func enqueue(cmd: SimCommand) -> void:
	_queue.append(cmd)


func _execute(cmd: SimCommand, ctx: TickContext) -> Result:
	var result: Result = cmd.validate(world, ctx)
	if result.ok:
		cmd.apply(world, ctx)
		command_log.append({"day": world.day, "type": cmd.get_type(), "company": cmd.company_id, "args": cmd.to_dict()})
		if command_log.size() > 2000:
			command_log.pop_front()
	return result


## Tạo command theo type đã đăng ký (dùng khi replay/nhận từ mạng).
func make_command(command_type: String, company_id: String, args: Dictionary) -> SimCommand:
	var script: Script = _command_types.get(command_type)
	if script == null:
		return null
	var cmd: SimCommand = script.new()
	cmd.company_id = company_id
	cmd.from_dict(args)
	return cmd


func has_command_type(command_type: String) -> bool:
	return _command_types.has(command_type)


## Lấy và xóa các event đã phát từ lần gọi trước.
func drain_events() -> Array[SimEvent]:
	var out: Array[SimEvent] = _pending_events
	_pending_events = []
	return out


func _dispatch(events: Array[SimEvent]) -> void:
	for e in events:
		var handlers: Array = _event_handlers.get(e.type, [])
		for h: Callable in handlers:
			h.call(e, world)


func _add_system(system: SimSystem) -> void:
	# Chèn ổn định theo phase (giữ thứ tự đăng ký trong cùng phase).
	var idx: int = _systems.size()
	for i in _systems.size():
		if _systems[i].get_phase() > system.get_phase():
			idx = i
			break
	_systems.insert(idx, system)


func systems() -> Array[SimSystem]:
	return _systems


# ---------------------------------------------------------------- save/load

func to_save_dict() -> Dictionary:
	var states: Dictionary = {}
	for id in world.state_ids():
		var st: ModuleState = world.get_state(id) as ModuleState
		states[id] = st.to_dict()
	return {
		"world": {
			"day": world.day,
			"seed": world.world_seed,
			"player_company_id": world.player_company_id,
			"id_counters": world.id_counters.duplicate(),
		},
		"modules": states,
	}


func load_save_dict(d: Dictionary) -> void:
	world = WorldState.new()
	var w: Dictionary = SaveUtil.dict(d, "world")
	world.day = SaveUtil.i(w, "day")
	world.world_seed = SaveUtil.i(w, "seed")
	world.player_company_id = SaveUtil.s(w, "player_company_id")
	world.id_counters = SaveUtil.int_map(SaveUtil.dict(w, "id_counters"))
	_create_states()
	var states: Dictionary = SaveUtil.dict(d, "modules")
	for id in world.state_ids():
		var st: ModuleState = world.get_state(id) as ModuleState
		st.from_dict(SaveUtil.dict(states, id))
	_queue.clear()
	_pending_events.clear()

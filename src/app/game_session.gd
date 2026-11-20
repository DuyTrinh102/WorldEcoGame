extends Node
## Phiên chơi: sở hữu Simulation, điều khiển thời gian, nhận command từ UI, lưu/tải.
## UI chỉ giao tiếp với mô phỏng qua đây (ghi) và qua *Queries (đọc).

signal game_started
signal day_advanced(day: int)
signal state_changed
signal speed_changed(index: int)

## Số ngày mô phỏng mỗi giây thực.
const SPEEDS: Array[float] = [0.0, 1.0, 2.0, 5.0, 10.0]
const MAX_TICKS_PER_FRAME: int = 4
const AUTOSAVE_SLOT: String = "autosave"
const QUICK_SLOT: String = "quicksave"

var content: ContentRegistry
var content_errors: Array[String] = []
var sim: Simulation
var speed_index: int = 0
var _last_speed: int = 1
var _accum: float = 0.0


func _ready() -> void:
	Loc.load_locale("vi")
	var loader := ContentLoader.new()
	content = loader.load_roots(ContentLoader.DEFAULT_ROOTS)
	content_errors = loader.errors
	if content_errors.is_empty():
		new_game()
	else:
		for e in content_errors:
			push_error(e)


func is_ready() -> bool:
	return sim != null


func world() -> WorldState:
	return sim.world


func company_id() -> String:
	return sim.world.player_company_id


func new_game(seed_value: int = -1) -> void:
	sim = Simulation.create_from_content(content)
	sim.new_game("default", seed_value if seed_value >= 0 else randi() % 1_000_000)
	SimBridge.clear()
	set_speed(0)
	_flush()
	game_started.emit()
	state_changed.emit()


func submit(cmd: SimCommand) -> Result:
	var r: Result = sim.submit(cmd)
	_flush()
	state_changed.emit()
	return r


func check(cmd: SimCommand) -> Result:
	return sim.check(cmd)


func set_speed(index: int) -> void:
	speed_index = clampi(index, 0, SPEEDS.size() - 1)
	if speed_index > 0:
		_last_speed = speed_index
	_accum = 0.0
	speed_changed.emit(speed_index)


func toggle_pause() -> void:
	set_speed(0 if speed_index > 0 else _last_speed)


func _process(delta: float) -> void:
	if sim == null or speed_index == 0:
		return
	_accum += delta * SPEEDS[speed_index]
	var ticks: int = mini(int(_accum), MAX_TICKS_PER_FRAME)
	if ticks <= 0:
		return
	_accum = minf(_accum - ticks, 1.0)
	for i in ticks:
		var month_end: bool = GameDate.is_month_end(sim.world.day)
		sim.step()
		if month_end:
			SaveService.save_to_file(sim, SaveService.slot_path(AUTOSAVE_SLOT))
	_flush()
	day_advanced.emit(sim.world.day)
	state_changed.emit()


## Chạy nhanh n ngày (nút "tua").
func advance_days(n: int) -> void:
	for i in n:
		sim.step()
	_flush()
	day_advanced.emit(sim.world.day)
	state_changed.emit()


func save_game(slot: String = QUICK_SLOT) -> Result:
	return SaveService.save_to_file(sim, SaveService.slot_path(slot))


func load_game(slot: String = QUICK_SLOT) -> Result:
	var fresh := Simulation.create_from_content(content)
	var r: Result = SaveService.load_from_file(fresh, SaveService.slot_path(slot))
	if r.ok:
		sim = fresh
		SimBridge.clear()
		set_speed(0)
		game_started.emit()
		state_changed.emit()
	return r


func has_save(slot: String = QUICK_SLOT) -> bool:
	return FileAccess.file_exists(SaveService.slot_path(slot))


func _flush() -> void:
	SimBridge.publish(sim.drain_events())

class_name ModuleContext
extends RefCounted
## Cổng đăng ký mà Simulation đưa cho từng module trong SimModule.register().

var _sim: Simulation
var _module_id: String


func _init(sim: Simulation, module_id: String) -> void:
	_sim = sim
	_module_id = module_id


## Đăng ký lớp state (phải kế thừa ModuleState) cho module này.
func register_state(state_script: Script) -> void:
	_sim._state_scripts[_module_id] = state_script


func register_system(system: SimSystem) -> void:
	_sim._add_system(system)


func register_command(command_type: String, command_script: Script) -> void:
	assert(not _sim._command_types.has(command_type), "Command trùng: " + command_type)
	_sim._command_types[command_type] = command_script


func register_event_handler(event_type: String, handler: Callable) -> void:
	if not _sim._event_handlers.has(event_type):
		_sim._event_handlers[event_type] = []
	(_sim._event_handlers[event_type] as Array).append(handler)


## Màn hình UI của module — app/ui tự thêm vào thanh điều hướng.
func register_ui_screen(screen_id: String, scene_or_script_path: String, title_key: String, order: int = 100) -> void:
	_sim.ui_screens.append({"id": screen_id, "path": scene_or_script_path, "title_key": title_key, "order": order, "module": _module_id})

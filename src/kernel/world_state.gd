class_name WorldState
extends RefCounted
## Gốc của toàn bộ trạng thái game — nguồn sự thật duy nhất.
## Mỗi module đăng ký một state con; truy cập qua world.get_state("module_id").

var day: int = 0
var world_seed: int = 0
var player_company_id: String = ""
var id_counters: Dictionary = {}
var _states: Dictionary = {}


func get_state(module_id: String) -> RefCounted:
	return _states.get(module_id) as RefCounted


func set_state(module_id: String, state: RefCounted) -> void:
	_states[module_id] = state


func has_state(module_id: String) -> bool:
	return _states.has(module_id)


func state_ids() -> Array[String]:
	var out: Array[String] = []
	for k: Variant in _states:
		out.append(str(k))
	out.sort()
	return out


## Sinh ID ổn định dạng "co_000001".
func new_id(prefix: String) -> String:
	var n: int = int(id_counters.get(prefix, 0)) + 1
	id_counters[prefix] = n
	return "%s_%06d" % [prefix, n]

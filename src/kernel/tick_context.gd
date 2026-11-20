class_name TickContext
extends RefCounted
## Ngữ cảnh truyền cho system/command trong một tick.

var day: int
var content: ContentRegistry
var world_seed: int
var events: Array[SimEvent] = []
var _rngs: Dictionary = {}


func _init(p_day: int, p_content: ContentRegistry, p_seed: int) -> void:
	day = p_day
	content = p_content
	world_seed = p_seed


## RNG tất định riêng cho từng luồng (thường là id của system) trong ngày hiện tại.
func rng(stream_id: String) -> RandomNumberGenerator:
	if not _rngs.has(stream_id):
		_rngs[stream_id] = RngStream.create(world_seed, stream_id, day)
	return _rngs[stream_id]


func emit(event_type: String, data: Dictionary = {}, text_key: String = "", importance: int = SimEvent.Importance.NORMAL, company_id: String = "") -> void:
	events.append(SimEvent.create(event_type, day, data, text_key, importance, company_id))


func is_month_end() -> bool:
	return GameDate.is_month_end(day)

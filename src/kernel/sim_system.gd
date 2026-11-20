class_name SimSystem
extends RefCounted
## Lớp cơ sở cho mọi system mô phỏng. KHÔNG được chạm Node/UI.

enum Frequency { DAILY, WEEKLY, MONTHLY }


func get_id() -> String:
	return ""


func get_phase() -> SimPhase.Phase:
	return SimPhase.Phase.MARKET


func get_frequency() -> Frequency:
	return Frequency.DAILY


## Logic chính. Đọc/ghi trạng thái qua `world`, lấy dữ liệu tĩnh/RNG/phát event qua `ctx`.
func run(_world: WorldState, _ctx: TickContext) -> void:
	pass

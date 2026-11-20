class_name SimCommand
extends RefCounted
## Lớp cơ sở cho mọi hành động thay đổi trạng thái (người chơi, AI, kịch bản).
## validate() không được thay đổi state; apply() chỉ chạy khi validate() thành công.

## Công ty phát lệnh.
var company_id: String = ""


func get_type() -> String:
	return ""


func validate(_world: WorldState, _ctx: TickContext) -> Result:
	return Result.success()


func apply(_world: WorldState, _ctx: TickContext) -> void:
	pass


## Tham số của lệnh (phục vụ replay/multiplayer).
func to_dict() -> Dictionary:
	return {}


func from_dict(_d: Dictionary) -> void:
	pass

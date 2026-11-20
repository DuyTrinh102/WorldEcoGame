class_name SimModule
extends RefCounted
## Lớp cơ sở cho một module tính năng (plugin). Module tự đăng ký state, system,
## command, event handler và màn hình UI thông qua ModuleContext.


func get_id() -> String:
	return ""


func get_dependencies() -> Array[String]:
	return []


func register(_ctx: ModuleContext) -> void:
	pass


## Khởi tạo state cho ván mới (chạy theo thứ tự phụ thuộc).
func on_new_game(_world: WorldState, _ctx: TickContext, _scenario: Dictionary) -> void:
	pass

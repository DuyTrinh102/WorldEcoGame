class_name SetFactoryActiveCommand
extends SimCommand
## Bật/tạm dừng nhà máy (tạm dừng vẫn tốn 30% chi phí cố định).

const TYPE := "production.set_active"

var factory_id: String = ""
var active: bool = true


static func create(company: String, factory: String, is_active: bool) -> SetFactoryActiveCommand:
	var c := SetFactoryActiveCommand.new()
	c.company_id = company
	c.factory_id = factory
	c.active = is_active
	return c


func get_type() -> String:
	return TYPE


func validate(world: WorldState, _ctx: TickContext) -> Result:
	var f: Dictionary = ProductionQueries.factory(world, factory_id)
	if f.is_empty() or str(f["company"]) != company_id:
		return Result.fail("ERR_FACTORY_NOT_OWNED")
	return Result.success()


func apply(world: WorldState, ctx: TickContext) -> void:
	var f: Dictionary = ProductionState.of(world).factories[factory_id]
	f["active"] = active
	if ctx.day >= int(f["complete_day"]):
		f["status"] = ProductionQueries.STATUS_RUNNING if active else ProductionQueries.STATUS_PAUSED


func to_dict() -> Dictionary:
	return {"factory": factory_id, "active": active}


func from_dict(d: Dictionary) -> void:
	factory_id = SaveUtil.s(d, "factory")
	active = SaveUtil.b(d, "active", true)

class_name ProductionState
extends ModuleState

## id -> {id, company, warehouse, country, facility, active, complete_day, status,
##        month_output, last_month_output, total_output, depreciated, build_cost}
var factories: Dictionary = {}


static func of(world: WorldState) -> ProductionState:
	return world.get_state("production") as ProductionState


func to_dict() -> Dictionary:
	return {"factories": factories.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	factories = {}
	var f: Dictionary = SaveUtil.dict(d, "factories")
	for k: Variant in f:
		var e: Dictionary = f[k]
		factories[str(k)] = {
			"id": SaveUtil.s(e, "id"),
			"company": SaveUtil.s(e, "company"),
			"warehouse": SaveUtil.s(e, "warehouse"),
			"country": SaveUtil.s(e, "country"),
			"facility": SaveUtil.s(e, "facility"),
			"active": SaveUtil.b(e, "active", true),
			"complete_day": SaveUtil.i(e, "complete_day"),
			"status": SaveUtil.s(e, "status", "building"),
			"month_output": SaveUtil.i(e, "month_output"),
			"last_month_output": SaveUtil.i(e, "last_month_output"),
			"total_output": SaveUtil.i(e, "total_output"),
			"depreciated": SaveUtil.i(e, "depreciated"),
			"build_cost": SaveUtil.i(e, "build_cost"),
		}

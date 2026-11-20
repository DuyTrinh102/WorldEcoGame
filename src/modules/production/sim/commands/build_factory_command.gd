class_name BuildFactoryCommand
extends SimCommand
## Xây nhà máy gắn với một kho (đầu vào lấy từ kho, đầu ra nhập vào kho).

const TYPE := "production.build_factory"

var warehouse_id: String = ""
var facility_id: String = ""


static func create(company: String, warehouse: String, facility: String) -> BuildFactoryCommand:
	var c := BuildFactoryCommand.new()
	c.company_id = company
	c.warehouse_id = warehouse
	c.facility_id = facility
	return c


func get_type() -> String:
	return TYPE


func validate(world: WorldState, ctx: TickContext) -> Result:
	var wh: Dictionary = InventoryQueries.warehouse(world, warehouse_id)
	if wh.is_empty() or str(wh["company"]) != company_id:
		return Result.fail("ERR_WAREHOUSE_NOT_OWNED")
	var f: FacilityDef = ctx.content.facility(facility_id)
	if f == null:
		return Result.fail("ERR_UNKNOWN_FACILITY")
	if FinanceQueries.cash(world, company_id) < f.build_cost:
		return Result.fail("ERR_NOT_ENOUGH_CASH", {"cash_cents": FinanceQueries.cash(world, company_id)})
	return Result.success()


func apply(world: WorldState, ctx: TickContext) -> void:
	var wh: Dictionary = InventoryQueries.warehouse(world, warehouse_id)
	var f: FacilityDef = ctx.content.facility(facility_id)
	var id: String = world.new_id("fac")
	ProductionState.of(world).factories[id] = {
		"id": id, "company": company_id, "warehouse": warehouse_id, "country": str(wh["country"]),
		"facility": facility_id, "active": true, "complete_day": ctx.day + f.build_days,
		"status": ProductionQueries.STATUS_BUILDING, "month_output": 0, "last_month_output": 0,
		"total_output": 0, "depreciated": 0, "build_cost": f.build_cost,
	}
	Ledger.post(world, ctx.day, company_id, "JE_FACTORY_BUILT", [Ledger.dr(Accounts.FIXED_ASSETS, f.build_cost), Ledger.cr(Accounts.CASH, f.build_cost)], {"facility": facility_id})
	ctx.emit("production.construction_started", {"factory": id, "facility": facility_id, "country": str(wh["country"]), "days": f.build_days, "cost_cents": f.build_cost}, "EVT_FACTORY_STARTED", SimEvent.Importance.NORMAL, company_id)


func to_dict() -> Dictionary:
	return {"warehouse": warehouse_id, "facility": facility_id}


func from_dict(d: Dictionary) -> void:
	warehouse_id = SaveUtil.s(d, "warehouse")
	facility_id = SaveUtil.s(d, "facility")

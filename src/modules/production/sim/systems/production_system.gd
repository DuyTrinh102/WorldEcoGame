class_name ProductionSystem
extends SimSystem
## Mỗi ngày: nhà máy tiêu hao nguyên liệu trong kho theo BOM, tạo sản phẩm.
## Giá vốn sản phẩm = giá vốn nguyên liệu + chi phí biến đổi (lao động, năng lượng).


func get_id() -> String:
	return "production.run"


func get_phase() -> SimPhase.Phase:
	return SimPhase.Phase.PRODUCTION


func run(world: WorldState, ctx: TickContext) -> void:
	for f in ProductionQueries.factories_of(world, ""):
		_run_factory(world, ctx, f)


func _run_factory(world: WorldState, ctx: TickContext, f: Dictionary) -> void:
	var company: String = str(f["company"])
	if ctx.day < int(f["complete_day"]):
		return
	if ctx.day == int(f["complete_day"]):
		ctx.emit("production.completed", {"factory": f["id"], "facility": f["facility"], "country": f["country"]}, "EVT_FACTORY_COMPLETED", SimEvent.Importance.HIGH, company)
	if not bool(f["active"]):
		f["status"] = ProductionQueries.STATUS_PAUSED
		return
	var def: FacilityDef = ctx.content.facility(str(f["facility"]))
	var wh: String = str(f["warehouse"])
	var out: int = def.capacity_per_day
	for k: String in def.inputs:
		var ratio: float = float(def.inputs[k])
		out = mini(out, int(floorf(float(InventoryQueries.available(world, wh, k)) / ratio)))
	if out <= 0:
		if str(f["status"]) != ProductionQueries.STATUS_NO_INPUT:
			ctx.emit("production.no_input", {"factory": f["id"], "facility": f["facility"], "country": f["country"]}, "EVT_FACTORY_NO_INPUT", SimEvent.Importance.HIGH, company)
		f["status"] = ProductionQueries.STATUS_NO_INPUT
		return
	f["status"] = ProductionQueries.STATUS_RUNNING
	var input_cost: int = 0
	for k: String in def.inputs:
		var need: int = mini(int(ceilf(float(out) * float(def.inputs[k]))), InventoryQueries.available(world, wh, k))
		input_cost += InventoryService.remove(world, wh, k, need)
	var var_cost: int = UnitPrice.total(def.variable_cost_per_unit, out)
	InventoryService.add(world, wh, def.output, out, input_cost + var_cost)
	Ledger.post(world, ctx.day, company, "JE_PRODUCTION", [Ledger.dr(Accounts.INVENTORY, var_cost), Ledger.cr(Accounts.CASH, var_cost)], {"commodity": def.output})
	f["month_output"] = int(f["month_output"]) + out
	f["total_output"] = int(f["total_output"]) + out

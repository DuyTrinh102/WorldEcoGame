class_name FactoryCostSystem
extends SimSystem
## Cuối tháng: chi phí cố định (lương, bảo trì) và khấu hao đường thẳng của nhà máy.

const PAUSED_OVERHEAD_RATIO: float = 0.3


func get_id() -> String:
	return "production.costs"


func get_phase() -> SimPhase.Phase:
	return SimPhase.Phase.FINANCE


func get_frequency() -> SimSystem.Frequency:
	return SimSystem.Frequency.MONTHLY


func run(world: WorldState, ctx: TickContext) -> void:
	for f in ProductionQueries.factories_of(world, ""):
		var company: String = str(f["company"])
		f["last_month_output"] = f["month_output"]
		f["month_output"] = 0
		if ctx.day < int(f["complete_day"]):
			continue
		var def: FacilityDef = ctx.content.facility(str(f["facility"]))
		var overhead: int = def.monthly_overhead if bool(f["active"]) else IntMath.mul_ratio(def.monthly_overhead, PAUSED_OVERHEAD_RATIO)
		var build_cost: int = int(f["build_cost"])
		var dep: int = mini(IntMath.div_round(build_cost, def.depreciation_years * 12), build_cost - int(f["depreciated"]))
		f["depreciated"] = int(f["depreciated"]) + dep
		Ledger.post(world, ctx.day, company, "JE_FACTORY_COSTS", [
			Ledger.dr(Accounts.FACTORY_OVERHEAD, overhead),
			Ledger.cr(Accounts.CASH, overhead),
			Ledger.dr(Accounts.DEPRECIATION, dep),
			Ledger.cr(Accounts.ACCUM_DEPRECIATION, dep),
		], {"facility": f["facility"]})

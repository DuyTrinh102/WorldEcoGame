class_name StorageCostSystem
extends SimSystem
## Cuối tháng: tiền thuê kho + phí lưu kho theo tấn.


func get_id() -> String:
	return "inventory.storage_cost"


func get_phase() -> SimPhase.Phase:
	return SimPhase.Phase.FINANCE


func get_frequency() -> SimSystem.Frequency:
	return SimSystem.Frequency.MONTHLY


func run(world: WorldState, ctx: TickContext) -> void:
	var rent: int = Money.from_float(ctx.content.setting_f("warehouse.monthly_rent", 12000.0))
	var per_t: int = UnitPrice.from_float(ctx.content.setting_f("warehouse.storage_per_t_month", 1.5))
	var st: InventoryState = InventoryState.of(world)
	var ids: Array = st.warehouses.keys()
	ids.sort()
	for wh: String in ids:
		var w: Dictionary = st.warehouses[wh]
		var cost: int = rent + UnitPrice.total(per_t, InventoryQueries.used(world, wh))
		Ledger.post(world, ctx.day, str(w["company"]), "JE_STORAGE", [Ledger.dr(Accounts.STORAGE_EXPENSE, cost), Ledger.cr(Accounts.CASH, cost)], {"country": w["country"]})

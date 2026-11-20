class_name ShipmentSystem
extends SimSystem
## Mỗi ngày: kiểm tra rủi ro trễ giữa hành trình, nhập kho khi hàng đến.


func get_id() -> String:
	return "logistics.shipments"


func get_phase() -> SimPhase.Phase:
	return SimPhase.Phase.LOGISTICS


func run(world: WorldState, ctx: TickContext) -> void:
	var st: LogisticsState = LogisticsState.of(world)
	var ids: Array = st.shipments.keys()
	ids.sort()
	var chance: float = ctx.content.setting_f("logistics.delay_chance", 0.1)
	var max_delay: int = ctx.content.setting_i("logistics.max_delay_days", 7)
	var rng: RandomNumberGenerator = ctx.rng(get_id())
	for id: String in ids:
		var s: Dictionary = st.shipments[id]
		var mid: int = (int(s["depart_day"]) + int(s["arrive_day"])) / 2
		if not bool(s["delay_checked"]) and ctx.day >= mid:
			s["delay_checked"] = true
			if rng.randf() < chance:
				var extra: int = rng.randi_range(2, max_delay)
				s["delayed_days"] = extra
				s["arrive_day"] = int(s["arrive_day"]) + extra
				ctx.emit("logistics.delayed", {"shipment": id, "commodity": s["commodity"], "to": s["to_country"], "days": extra}, "EVT_SHIPMENT_DELAYED", SimEvent.Importance.HIGH, str(s["company"]))
		if ctx.day >= int(s["arrive_day"]):
			var value: int = int(s["value"])
			InventoryService.add(world, str(s["to_wh"]), str(s["commodity"]), int(s["qty"]), value)
			Ledger.post(world, ctx.day, str(s["company"]), "JE_SHIPMENT_ARRIVE", [
				Ledger.dr(Accounts.INVENTORY, value),
				Ledger.cr(Accounts.INVENTORY_TRANSIT, value),
			], {"commodity": s["commodity"]})
			st.shipments.erase(id)
			ctx.emit("logistics.arrived", {"shipment": id, "commodity": s["commodity"], "qty": s["qty"], "to": s["to_country"]}, "EVT_SHIPMENT_ARRIVED", SimEvent.Importance.NORMAL, str(s["company"]))

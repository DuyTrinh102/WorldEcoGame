class_name ReceivablesSystem
extends SimSystem
## Thu tiền các khoản phải thu đến hạn.


func get_id() -> String:
	return "trade.receivables"


func get_phase() -> SimPhase.Phase:
	return SimPhase.Phase.TRADE


func run(world: WorldState, ctx: TickContext) -> void:
	var st: TradeState = TradeState.of(world)
	var ids: Array = st.receivables.keys()
	ids.sort()
	for id: String in ids:
		var r: Dictionary = st.receivables[id]
		if ctx.day < int(r["due_day"]):
			continue
		var amount: int = int(r["amount"])
		Ledger.post(world, ctx.day, str(r["company"]), "JE_COLLECTION", [Ledger.dr(Accounts.CASH, amount), Ledger.cr(Accounts.RECEIVABLES, amount)], {"country": r["country"]})
		st.receivables.erase(id)
		ctx.emit("trade.collected", {"amount_cents": amount, "country": r["country"]}, "EVT_COLLECTED", SimEvent.Importance.LOW, str(r["company"]))

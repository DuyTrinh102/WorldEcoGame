class_name TradeQueries
extends RefCounted


static func receivables_of(world: WorldState, company_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var st: TradeState = TradeState.of(world)
	var ids: Array = st.receivables.keys()
	ids.sort()
	for id: String in ids:
		if str(st.receivables[id]["company"]) == company_id:
			out.append(st.receivables[id])
	return out


static func total_receivables(world: WorldState, company_id: String) -> int:
	var total: int = 0
	for r in receivables_of(world, company_id):
		total += int(r["amount"])
	return total


static func recent_trades(world: WorldState, company_id: String, limit: int = 30) -> Array:
	var out: Array = []
	var entries: Array = TradeState.of(world).trade_log
	for i in range(entries.size() - 1, -1, -1):
		if str(entries[i]["company"]) == company_id:
			out.append(entries[i])
			if out.size() >= limit:
				break
	return out

class_name MarketSystem
extends SimSystem
## Cập nhật thị trường mỗi ngày, ghi lịch sử giá mỗi tuần, tin biến động giá mỗi tháng.

const MOVE_THRESHOLD: float = 0.12
const MAX_MOVE_NEWS: int = 3


func get_id() -> String:
	return "market.update"


func get_phase() -> SimPhase.Phase:
	return SimPhase.Phase.MARKET


func run(world: WorldState, ctx: TickContext) -> void:
	var st: MarketState = MarketState.of(world)
	DetailedMarketModel.step_all(st, ctx, WorldQueries.modifiers(world))
	record(st, ctx, true)


static func record(st: MarketState, ctx: TickContext, emit_news: bool) -> void:
	if GameDate.is_week_end(ctx.day):
		for kid in ctx.content.commodity_ids:
			for cid in ctx.content.country_ids:
				st.push_history(MarketState.history_key(cid, kid), float(st.markets[cid][kid]["price"]))
			st.push_history(MarketState.history_key(MarketState.WORLD_KEY, kid), float(st.world_price[kid]))
	if GameDate.is_month_end(ctx.day):
		var moves: Array = []
		for cid in ctx.content.country_ids:
			for kid in ctx.content.commodity_ids:
				var e: Dictionary = st.markets[cid][kid]
				var change: float = float(e["price"]) / float(e["month_open"]) - 1.0
				if absf(change) >= MOVE_THRESHOLD:
					moves.append({"country": cid, "commodity": kid, "change": change})
				e["month_open"] = e["price"]
		if emit_news and not moves.is_empty():
			moves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				if absf(float(a["change"])) == absf(float(b["change"])):
					return str(a["country"]) + str(a["commodity"]) < str(b["country"]) + str(b["commodity"])
				return absf(float(a["change"])) > absf(float(b["change"])))
			for i in mini(MAX_MOVE_NEWS, moves.size()):
				var m: Dictionary = moves[i]
				var key: String = "EVT_PRICE_UP" if float(m["change"]) > 0.0 else "EVT_PRICE_DOWN"
				ctx.emit("market.price_move", {"country": m["country"], "commodity": m["commodity"], "pct": "%.0f" % (absf(float(m["change"])) * 100.0)}, key)

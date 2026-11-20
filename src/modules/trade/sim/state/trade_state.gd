class_name TradeState
extends ModuleState

const LOG_LIMIT: int = 200

## id -> {id, company, amount, due_day, country, commodity}
var receivables: Dictionary = {}
## Lịch sử giao dịch gần nhất: {day, company, side, country, commodity, qty, unit_price, total, profit}
var trade_log: Array = []


static func of(world: WorldState) -> TradeState:
	return world.get_state("trade") as TradeState


func log_trade(entry: Dictionary) -> void:
	trade_log.append(entry)
	if trade_log.size() > LOG_LIMIT:
		trade_log.pop_front()


func to_dict() -> Dictionary:
	return {"receivables": receivables.duplicate(true), "trade_log": trade_log.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	receivables = {}
	var r: Dictionary = SaveUtil.dict(d, "receivables")
	for k: Variant in r:
		var e: Dictionary = r[k]
		receivables[str(k)] = {
			"id": SaveUtil.s(e, "id"), "company": SaveUtil.s(e, "company"), "amount": SaveUtil.i(e, "amount"),
			"due_day": SaveUtil.i(e, "due_day"), "country": SaveUtil.s(e, "country"), "commodity": SaveUtil.s(e, "commodity"),
		}
	trade_log = []
	for v: Variant in SaveUtil.arr(d, "trade_log"):
		var e: Dictionary = v
		trade_log.append({
			"day": SaveUtil.i(e, "day"), "company": SaveUtil.s(e, "company"), "side": SaveUtil.s(e, "side"),
			"country": SaveUtil.s(e, "country"), "commodity": SaveUtil.s(e, "commodity"), "qty": SaveUtil.i(e, "qty"),
			"unit_price": SaveUtil.i(e, "unit_price"), "total": SaveUtil.i(e, "total"), "profit": SaveUtil.i(e, "profit"),
		})

class_name LogisticsState
extends ModuleState

## id -> {id, company, from_wh, to_wh, from_country, to_country, commodity, qty, value, freight,
##        depart_day, arrive_day, delay_checked, delayed_days}
var shipments: Dictionary = {}


static func of(world: WorldState) -> LogisticsState:
	return world.get_state("logistics") as LogisticsState


func to_dict() -> Dictionary:
	return {"shipments": shipments.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	shipments = {}
	var s: Dictionary = SaveUtil.dict(d, "shipments")
	for k: Variant in s:
		var e: Dictionary = s[k]
		shipments[str(k)] = {
			"id": SaveUtil.s(e, "id"),
			"company": SaveUtil.s(e, "company"),
			"from_wh": SaveUtil.s(e, "from_wh"),
			"to_wh": SaveUtil.s(e, "to_wh"),
			"from_country": SaveUtil.s(e, "from_country"),
			"to_country": SaveUtil.s(e, "to_country"),
			"commodity": SaveUtil.s(e, "commodity"),
			"qty": SaveUtil.i(e, "qty"),
			"value": SaveUtil.i(e, "value"),
			"freight": SaveUtil.i(e, "freight"),
			"depart_day": SaveUtil.i(e, "depart_day"),
			"arrive_day": SaveUtil.i(e, "arrive_day"),
			"delay_checked": SaveUtil.b(e, "delay_checked"),
			"delayed_days": SaveUtil.i(e, "delayed_days"),
		}

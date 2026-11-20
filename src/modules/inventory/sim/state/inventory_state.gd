class_name InventoryState
extends ModuleState

## wh_id -> {id, company, country, capacity (Quantity), opened_day}
var warehouses: Dictionary = {}
## wh_id -> commodity_id -> {qty: Quantity, cost: cent}
var stock: Dictionary = {}


static func of(world: WorldState) -> InventoryState:
	return world.get_state("inventory") as InventoryState


func to_dict() -> Dictionary:
	return {"warehouses": warehouses.duplicate(true), "stock": stock.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	warehouses = {}
	var w: Dictionary = SaveUtil.dict(d, "warehouses")
	for k: Variant in w:
		var e: Dictionary = w[k]
		warehouses[str(k)] = {
			"id": SaveUtil.s(e, "id"),
			"company": SaveUtil.s(e, "company"),
			"country": SaveUtil.s(e, "country"),
			"capacity": SaveUtil.i(e, "capacity"),
			"opened_day": SaveUtil.i(e, "opened_day"),
		}
	stock = {}
	var s: Dictionary = SaveUtil.dict(d, "stock")
	for wh: Variant in s:
		var per: Dictionary = {}
		for kid: Variant in s[wh]:
			var lot: Dictionary = s[wh][kid]
			per[str(kid)] = {"qty": SaveUtil.i(lot, "qty"), "cost": SaveUtil.i(lot, "cost")}
		stock[str(wh)] = per

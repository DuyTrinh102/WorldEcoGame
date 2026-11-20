class_name MarketState
extends ModuleState

const HISTORY_LIMIT: int = 104
const WORLD_KEY: String = "WORLD"

## country_id -> commodity_id -> {price, stock, base_prod, base_cons, scale, price_ema, month_open}
var markets: Dictionary = {}
## commodity_id -> giá thế giới (bình quân gia quyền)
var world_price: Dictionary = {}
## "country/commodity" -> Array[float] giá theo tuần
var history: Dictionary = {}


static func of(world: WorldState) -> MarketState:
	return world.get_state("market") as MarketState


func entry(country_id: String, commodity_id: String) -> Dictionary:
	return (markets.get(country_id, {}) as Dictionary).get(commodity_id, {})


static func history_key(country_id: String, commodity_id: String) -> String:
	return "%s/%s" % [country_id, commodity_id]


func push_history(key: String, value: float) -> void:
	if not history.has(key):
		history[key] = []
	var list: Array = history[key]
	list.append(value)
	if list.size() > HISTORY_LIMIT:
		list.pop_front()


const ENTRY_FIELDS: Array[String] = ["price", "stock", "base_prod", "base_cons", "scale", "price_ema", "month_open"]


func to_dict() -> Dictionary:
	var m: Dictionary = {}
	for cid: String in markets:
		var per: Dictionary = {}
		for kid: String in markets[cid]:
			var e: Dictionary = markets[cid][kid]
			var values: Array = []
			for field in ENTRY_FIELDS:
				values.append(float(e[field]))
			per[kid] = SaveUtil.floats_to_b64(values)
		m[cid] = per
	var h: Dictionary = {}
	for k: String in history:
		h[k] = SaveUtil.floats_to_b64(history[k])
	var wp_keys: Array = world_price.keys()
	wp_keys.sort()
	var wp_values: Array = []
	for k: Variant in wp_keys:
		wp_values.append(float(world_price[k]))
	return {"fields": ENTRY_FIELDS.duplicate(), "markets": m, "world_price_keys": wp_keys, "world_price": SaveUtil.floats_to_b64(wp_values), "history": h}


func from_dict(d: Dictionary) -> void:
	markets = {}
	var m: Dictionary = SaveUtil.dict(d, "markets")
	for cid: Variant in m:
		var per: Dictionary = {}
		for kid: Variant in m[cid]:
			var values: PackedFloat64Array = SaveUtil.b64_to_floats(str(m[cid][kid]))
			var e: Dictionary = {}
			for i in ENTRY_FIELDS.size():
				e[ENTRY_FIELDS[i]] = values[i] if i < values.size() else 0.0
			per[str(kid)] = e
		markets[str(cid)] = per
	world_price = {}
	var keys: Array = SaveUtil.arr(d, "world_price_keys")
	var wp: PackedFloat64Array = SaveUtil.b64_to_floats(SaveUtil.s(d, "world_price"))
	for i in mini(keys.size(), wp.size()):
		world_price[str(keys[i])] = wp[i]
	history = {}
	var h: Dictionary = SaveUtil.dict(d, "history")
	for k: Variant in h:
		var list: Array = []
		for v in SaveUtil.b64_to_floats(str(h[k])):
			list.append(v)
		history[str(k)] = list

class_name MarketQueries
extends RefCounted
## API chỉ-đọc cho UI / AI / module khác về giá và thị trường.


static func price(world: WorldState, country_id: String, commodity_id: String) -> float:
	return float(MarketState.of(world).entry(country_id, commodity_id).get("price", 0.0))


static func world_price(world: WorldState, commodity_id: String) -> float:
	return float(MarketState.of(world).world_price.get(commodity_id, 0.0))


static func stock(world: WorldState, country_id: String, commodity_id: String) -> float:
	return float(MarketState.of(world).entry(country_id, commodity_id).get("stock", 0.0))


static func entry(world: WorldState, country_id: String, commodity_id: String) -> Dictionary:
	return MarketState.of(world).entry(country_id, commodity_id)


## % thay đổi giá từ đầu tháng.
static func month_change(world: WorldState, country_id: String, commodity_id: String) -> float:
	var e: Dictionary = entry(world, country_id, commodity_id)
	if e.is_empty() or float(e["month_open"]) <= 0.0:
		return 0.0
	return float(e["price"]) / float(e["month_open"]) - 1.0


static func history(world: WorldState, country_id: String, commodity_id: String) -> Array:
	return MarketState.of(world).history.get(MarketState.history_key(country_id, commodity_id), [])


## Báo giá cho lệnh mua/bán khối lượng qty (Quantity ×1000), có trượt giá theo độ sâu thị trường.
## Trả về {ok, error_key, unit_price (UnitPrice), total (cent), max_qty}
static func quote(world: WorldState, content: ContentRegistry, country_id: String, commodity_id: String, qty: int, is_buy: bool) -> Dictionary:
	var e: Dictionary = entry(world, country_id, commodity_id)
	if e.is_empty():
		return {"ok": false, "error_key": "ERR_NO_MARKET", "unit_price": 0, "total": 0, "max_qty": 0}
	var q: float = Quantity.to_float(qty)
	var slip: float = content.setting_f("market.slippage", 0.5)
	var d: float = DetailedMarketModel.depth(content, e)
	var p: float = float(e["price"])
	var max_qty: int = Quantity.from_float(float(e["stock"]) * content.setting_f("market.max_order_stock_ratio", 0.5))
	var avg: float = p * (1.0 + 0.5 * slip * q / d) if is_buy else p * maxf(0.2, 1.0 - 0.5 * slip * q / d)
	var unit_price: int = UnitPrice.from_float(avg)
	var result: Dictionary = {"ok": true, "error_key": "", "unit_price": unit_price, "total": UnitPrice.total(unit_price, qty), "max_qty": max_qty}
	if qty <= 0:
		result["ok"] = false
		result["error_key"] = "ERR_QTY_POSITIVE"
	elif is_buy and qty > max_qty:
		result["ok"] = false
		result["error_key"] = "ERR_MARKET_SUPPLY"
	return result

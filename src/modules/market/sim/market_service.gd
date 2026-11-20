class_name MarketService
extends RefCounted
## Thao tác GHI lên thị trường — chỉ được gọi từ command/system (không gọi từ UI).


## Khớp lệnh với thị trường: cập nhật tồn kho NPC và tác động giá. Trả về báo giá đã khớp.
static func execute(world: WorldState, content: ContentRegistry, country_id: String, commodity_id: String, qty: int, is_buy: bool) -> Dictionary:
	var q: Dictionary = MarketQueries.quote(world, content, country_id, commodity_id, qty, is_buy)
	if not bool(q["ok"]):
		return q
	var e: Dictionary = MarketState.of(world).entry(country_id, commodity_id)
	var c: CommodityDef = content.commodity(commodity_id)
	var amount: float = Quantity.to_float(qty)
	var impact: float = content.setting_f("market.slippage", 0.5) * amount / DetailedMarketModel.depth(content, e)
	if is_buy:
		e["stock"] = maxf(0.0, float(e["stock"]) - amount)
		e["price"] = minf(float(e["price"]) * (1.0 + impact), c.base_price * content.setting_f("market.price_cap_ratio", 4.0))
	else:
		e["stock"] = float(e["stock"]) + amount
		e["price"] = maxf(float(e["price"]) * maxf(0.5, 1.0 - impact), c.base_price * content.setting_f("market.price_floor_ratio", 0.25))
	return q

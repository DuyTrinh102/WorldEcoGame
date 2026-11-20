class_name CommodityDef
extends RefCounted
## Định nghĩa tĩnh một loại hàng hóa (đọc từ data/*/commodities/*.json).

var id: String
var name_key: String
var category: String
var unit: String = "t"
var base_price: float = 0.0
var color: Color = Color.WHITE
## Trọng số nhu cầu theo đầu người (tương đối, sẽ được hiệu chỉnh để tổng cầu = tổng cung).
var demand_weight: float = 1.0
var price_elasticity: float = -0.3
var income_elasticity: float = 0.5
var supply_elasticity: float = 0.2
## Tốc độ điều chỉnh giá theo độ lệch tồn kho/mục tiêu.
var adjust_speed: float = 0.02
var max_daily_change: float = 0.03
## 12 hệ số mùa vụ áp lên sản lượng (tháng 1..12).
var seasonality: Array[float] = []
var storage: String = "dry"
var monthly_loss_rate: float = 0.0


static func from_dict(d: Dictionary, errors: Array[String]) -> CommodityDef:
	var c := CommodityDef.new()
	c.id = ContentUtil.req_str(d, "id", errors, "commodity")
	c.name_key = str(d.get("name_key", "COMMODITY_" + c.id.to_upper()))
	c.category = ContentUtil.req_str(d, "category", errors, c.id)
	c.unit = str(d.get("unit", "t"))
	c.base_price = ContentUtil.req_float(d, "base_price", errors, c.id)
	c.color = Color.from_string(str(d.get("color", "#ffffff")), Color.WHITE)
	var m: Dictionary = d.get("market", {})
	c.demand_weight = float(m.get("demand_weight", 1.0))
	c.price_elasticity = float(m.get("price_elasticity", -0.3))
	c.income_elasticity = float(m.get("income_elasticity", 0.5))
	c.supply_elasticity = float(m.get("supply_elasticity", 0.2))
	c.adjust_speed = float(m.get("adjust_speed", 0.02))
	c.max_daily_change = float(m.get("max_daily_change", 0.03))
	var season: Array = d.get("seasonality", [])
	if season.is_empty():
		for i in 12:
			c.seasonality.append(1.0)
	elif season.size() != 12:
		errors.append("%s: seasonality phải có 12 phần tử" % c.id)
	else:
		for v: Variant in season:
			c.seasonality.append(float(v))
	c.storage = str(d.get("storage", "dry"))
	c.monthly_loss_rate = float(d.get("perishable", {}).get("monthly_loss_rate", 0.0))
	if c.base_price <= 0.0:
		errors.append("%s: base_price phải > 0" % c.id)
	return c

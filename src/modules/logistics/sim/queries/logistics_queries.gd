class_name LogisticsQueries
extends RefCounted


## Báo giá vận chuyển: {distance_km, days, freight_per_unit (UnitPrice), freight (cent)}
static func quote(content: ContentRegistry, from_country: String, to_country: String, qty: int) -> Dictionary:
	var km: float = WorldQueries.sea_distance_km(content, from_country, to_country)
	var speed: float = content.setting_f("logistics.ship_speed_km_per_day", 650.0)
	var port_days: int = content.setting_i("logistics.port_days", 2)
	var days: int = int(ceilf(km / speed)) + port_days
	var per_t: float = content.setting_f("logistics.port_handling_per_t", 12.0) + content.setting_f("logistics.freight_per_t_per_1000km", 4.5) * km / 1000.0
	per_t = maxf(per_t, content.setting_f("logistics.min_freight_per_t", 15.0))
	var unit: int = UnitPrice.from_float(per_t)
	return {"distance_km": km, "days": days, "freight_per_unit": unit, "freight": UnitPrice.total(unit, qty)}


static func shipments_of(world: WorldState, company_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var st: LogisticsState = LogisticsState.of(world)
	var ids: Array = st.shipments.keys()
	ids.sort()
	for id: String in ids:
		if company_id.is_empty() or str(st.shipments[id]["company"]) == company_id:
			out.append(st.shipments[id])
	return out


## Tiến độ 0..1 của chuyến hàng tại ngày hiện tại.
static func progress(world: WorldState, shipment: Dictionary) -> float:
	var total: int = maxi(1, int(shipment["arrive_day"]) - int(shipment["depart_day"]))
	return clampf(float(world.day - int(shipment["depart_day"])) / float(total), 0.0, 1.0)


## Tổng giá trị hàng đang đi đường (khớp tài khoản inventory_transit).
static func in_transit_value(world: WorldState, company_id: String) -> int:
	var total: int = 0
	for s in shipments_of(world, company_id):
		total += int(s["value"])
	return total

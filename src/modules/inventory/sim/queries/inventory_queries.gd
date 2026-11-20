class_name InventoryQueries
extends RefCounted


static func warehouse(world: WorldState, wh_id: String) -> Dictionary:
	return InventoryState.of(world).warehouses.get(wh_id, {})


static func warehouses_of(world: WorldState, company_id: String) -> Array[String]:
	var out: Array[String] = []
	var st: InventoryState = InventoryState.of(world)
	for k: Variant in st.warehouses:
		if str(st.warehouses[k]["company"]) == company_id:
			out.append(str(k))
	out.sort()
	return out


## Kho của công ty tại quốc gia (mỗi công ty tối đa 1 kho/quốc gia trong prototype). "" nếu chưa có.
static func warehouse_in(world: WorldState, company_id: String, country_id: String) -> String:
	for wh in warehouses_of(world, company_id):
		if str(warehouse(world, wh)["country"]) == country_id:
			return wh
	return ""


static func available(world: WorldState, wh_id: String, commodity_id: String) -> int:
	var per: Dictionary = InventoryState.of(world).stock.get(wh_id, {})
	return int((per.get(commodity_id, {}) as Dictionary).get("qty", 0))


static func cost_of(world: WorldState, wh_id: String, commodity_id: String) -> int:
	var per: Dictionary = InventoryState.of(world).stock.get(wh_id, {})
	return int((per.get(commodity_id, {}) as Dictionary).get("cost", 0))


## Giá vốn bình quân (UnitPrice).
static func avg_cost(world: WorldState, wh_id: String, commodity_id: String) -> int:
	return UnitPrice.from_total(cost_of(world, wh_id, commodity_id), available(world, wh_id, commodity_id))


static func used(world: WorldState, wh_id: String) -> int:
	var total: int = 0
	var per: Dictionary = InventoryState.of(world).stock.get(wh_id, {})
	for k: Variant in per:
		total += int(per[k]["qty"])
	return total


static func free_capacity(world: WorldState, wh_id: String) -> int:
	return int(warehouse(world, wh_id).get("capacity", 0)) - used(world, wh_id)


## Danh sách hàng trong kho (đã sắp xếp theo ID).
static func items(world: WorldState, wh_id: String) -> Array[String]:
	var out: Array[String] = []
	for k: Variant in InventoryState.of(world).stock.get(wh_id, {}):
		out.append(str(k))
	out.sort()
	return out


## Tổng giá trị sổ sách tồn kho của công ty.
static func total_cost(world: WorldState, company_id: String) -> int:
	var total: int = 0
	for wh in warehouses_of(world, company_id):
		for kid in items(world, wh):
			total += cost_of(world, wh, kid)
	return total

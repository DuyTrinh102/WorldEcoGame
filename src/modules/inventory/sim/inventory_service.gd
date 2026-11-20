class_name InventoryService
extends RefCounted
## Thao tác GHI lên tồn kho — chỉ gọi từ command/system. Giá vốn bình quân gia quyền.
## Tồn kho (tổng cost) luôn khớp tài khoản "inventory" trong sổ cái — người gọi tự ghi bút toán.


static func create_warehouse(world: WorldState, ctx: TickContext, company_id: String, country_id: String) -> String:
	var st: InventoryState = InventoryState.of(world)
	var id: String = world.new_id("wh")
	var capacity_t: float = ctx.content.setting_f("warehouse.capacity_t", 30000.0)
	st.warehouses[id] = {"id": id, "company": company_id, "country": country_id, "capacity": Quantity.from_float(capacity_t), "opened_day": world.day}
	st.stock[id] = {}
	return id


static func add(world: WorldState, wh_id: String, commodity_id: String, qty: int, cost: int) -> void:
	assert(qty >= 0 and cost >= 0)
	var per: Dictionary = InventoryState.of(world).stock[wh_id]
	if not per.has(commodity_id):
		per[commodity_id] = {"qty": 0, "cost": 0}
	var lot: Dictionary = per[commodity_id]
	lot["qty"] = int(lot["qty"]) + qty
	lot["cost"] = int(lot["cost"]) + cost


## Xuất kho, trả về giá vốn của phần xuất. Xuất hết thì lấy toàn bộ cost (không lệch làm tròn).
static func remove(world: WorldState, wh_id: String, commodity_id: String, qty: int) -> int:
	var per: Dictionary = InventoryState.of(world).stock[wh_id]
	var lot: Dictionary = per.get(commodity_id, {"qty": 0, "cost": 0})
	var have: int = int(lot["qty"])
	assert(qty > 0 and qty <= have, "InventoryService.remove: không đủ hàng")
	var cost: int
	if qty == have:
		cost = int(lot["cost"])
		per.erase(commodity_id)
	else:
		cost = IntMath.mul_div(int(lot["cost"]), qty, have)
		lot["qty"] = have - qty
		lot["cost"] = int(lot["cost"]) - cost
	return cost

class_name ShipCommand
extends SimCommand
## Vận chuyển hàng giữa hai kho của cùng công ty. Cước phí được vốn hóa vào giá vốn hàng.

const TYPE := "logistics.ship"

var from_wh: String = ""
var to_wh: String = ""
var commodity_id: String = ""
var qty: int = 0


static func create(company: String, p_from: String, p_to: String, commodity: String, quantity: int) -> ShipCommand:
	var c := ShipCommand.new()
	c.company_id = company
	c.from_wh = p_from
	c.to_wh = p_to
	c.commodity_id = commodity
	c.qty = quantity
	return c


func get_type() -> String:
	return TYPE


func validate(world: WorldState, ctx: TickContext) -> Result:
	var a: Dictionary = InventoryQueries.warehouse(world, from_wh)
	var b: Dictionary = InventoryQueries.warehouse(world, to_wh)
	if a.is_empty() or b.is_empty() or str(a["company"]) != company_id or str(b["company"]) != company_id:
		return Result.fail("ERR_WAREHOUSE_NOT_OWNED")
	if from_wh == to_wh:
		return Result.fail("ERR_SAME_WAREHOUSE")
	if qty <= 0:
		return Result.fail("ERR_QTY_POSITIVE")
	if qty > InventoryQueries.available(world, from_wh, commodity_id):
		return Result.fail("ERR_NOT_ENOUGH_STOCK")
	var q: Dictionary = LogisticsQueries.quote(ctx.content, str(a["country"]), str(b["country"]), qty)
	if FinanceQueries.cash(world, company_id) < int(q["freight"]):
		return Result.fail("ERR_NOT_ENOUGH_CASH", {"cash_cents": FinanceQueries.cash(world, company_id)})
	return Result.success(q)


func apply(world: WorldState, ctx: TickContext) -> void:
	var a: Dictionary = InventoryQueries.warehouse(world, from_wh)
	var b: Dictionary = InventoryQueries.warehouse(world, to_wh)
	var q: Dictionary = LogisticsQueries.quote(ctx.content, str(a["country"]), str(b["country"]), qty)
	var freight: int = int(q["freight"])
	var goods_cost: int = InventoryService.remove(world, from_wh, commodity_id, qty)
	Ledger.post(world, ctx.day, company_id, "JE_SHIPMENT_DEPART", [
		Ledger.dr(Accounts.INVENTORY_TRANSIT, goods_cost + freight),
		Ledger.cr(Accounts.INVENTORY, goods_cost),
		Ledger.cr(Accounts.CASH, freight),
	], {"commodity": commodity_id})
	var id: String = world.new_id("sh")
	LogisticsState.of(world).shipments[id] = {
		"id": id, "company": company_id, "from_wh": from_wh, "to_wh": to_wh,
		"from_country": str(a["country"]), "to_country": str(b["country"]),
		"commodity": commodity_id, "qty": qty, "value": goods_cost + freight, "freight": freight,
		"depart_day": ctx.day, "arrive_day": ctx.day + int(q["days"]),
		"delay_checked": false, "delayed_days": 0,
	}
	ctx.emit("logistics.departed", {
		"shipment": id, "commodity": commodity_id, "qty": qty, "from": str(a["country"]), "to": str(b["country"]),
		"days": q["days"], "freight_cents": freight,
	}, "EVT_SHIPMENT_DEPARTED", SimEvent.Importance.NORMAL, company_id)


func to_dict() -> Dictionary:
	return {"from_wh": from_wh, "to_wh": to_wh, "commodity": commodity_id, "qty": qty}


func from_dict(d: Dictionary) -> void:
	from_wh = SaveUtil.s(d, "from_wh")
	to_wh = SaveUtil.s(d, "to_wh")
	commodity_id = SaveUtil.s(d, "commodity")
	qty = SaveUtil.i(d, "qty")

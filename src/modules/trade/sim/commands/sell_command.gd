class_name SellCommand
extends SimCommand
## Bán hàng từ kho cho thị trường tại quốc gia của kho.
## Ghi doanh thu + công nợ phải thu ngay; tiền mặt về sau N ngày (lợi nhuận ≠ dòng tiền).

const TYPE := "trade.sell"

var warehouse_id: String = ""
var commodity_id: String = ""
var qty: int = 0


static func create(company: String, warehouse: String, commodity: String, quantity: int) -> SellCommand:
	var c := SellCommand.new()
	c.company_id = company
	c.warehouse_id = warehouse
	c.commodity_id = commodity
	c.qty = quantity
	return c


func get_type() -> String:
	return TYPE


func validate(world: WorldState, ctx: TickContext) -> Result:
	var wh: Dictionary = InventoryQueries.warehouse(world, warehouse_id)
	if wh.is_empty() or str(wh["company"]) != company_id:
		return Result.fail("ERR_WAREHOUSE_NOT_OWNED")
	if qty <= 0:
		return Result.fail("ERR_QTY_POSITIVE")
	if qty > InventoryQueries.available(world, warehouse_id, commodity_id):
		return Result.fail("ERR_NOT_ENOUGH_STOCK")
	var q: Dictionary = MarketQueries.quote(world, ctx.content, str(wh["country"]), commodity_id, qty, false)
	if not bool(q["ok"]):
		return Result.fail(str(q["error_key"]))
	return Result.success(q)


func apply(world: WorldState, ctx: TickContext) -> void:
	var country: String = str(InventoryQueries.warehouse(world, warehouse_id)["country"])
	var cost: int = InventoryService.remove(world, warehouse_id, commodity_id, qty)
	var q: Dictionary = MarketService.execute(world, ctx.content, country, commodity_id, qty, false)
	var revenue: int = int(q["total"])
	Ledger.post(world, ctx.day, company_id, "JE_SALE", [
		Ledger.dr(Accounts.RECEIVABLES, revenue),
		Ledger.cr(Accounts.REVENUE, revenue),
		Ledger.dr(Accounts.COGS, cost),
		Ledger.cr(Accounts.INVENTORY, cost),
	], {"commodity": commodity_id, "country": country})
	var st: TradeState = TradeState.of(world)
	var rid: String = world.new_id("ar")
	st.receivables[rid] = {"id": rid, "company": company_id, "amount": revenue, "due_day": ctx.day + ctx.content.setting_i("finance.receivable_days", 30), "country": country, "commodity": commodity_id}
	st.log_trade({"day": ctx.day, "company": company_id, "side": "sell", "country": country, "commodity": commodity_id, "qty": qty, "unit_price": q["unit_price"], "total": revenue, "profit": revenue - cost})
	ctx.emit("trade.sold", {"country": country, "commodity": commodity_id, "qty": qty, "total_cents": revenue, "profit_cents": revenue - cost}, "EVT_SOLD", SimEvent.Importance.NORMAL, company_id)


func to_dict() -> Dictionary:
	return {"warehouse": warehouse_id, "commodity": commodity_id, "qty": qty}


func from_dict(d: Dictionary) -> void:
	warehouse_id = SaveUtil.s(d, "warehouse")
	commodity_id = SaveUtil.s(d, "commodity")
	qty = SaveUtil.i(d, "qty")

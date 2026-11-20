class_name BuyCommand
extends SimCommand
## Mua hàng từ thị trường một quốc gia, nhập vào kho của công ty tại quốc gia đó. Trả tiền ngay.

const TYPE := "trade.buy"

var country_id: String = ""
var commodity_id: String = ""
var qty: int = 0


static func create(company: String, country: String, commodity: String, quantity: int) -> BuyCommand:
	var c := BuyCommand.new()
	c.company_id = company
	c.country_id = country
	c.commodity_id = commodity
	c.qty = quantity
	return c


func get_type() -> String:
	return TYPE


func validate(world: WorldState, ctx: TickContext) -> Result:
	var wh: String = InventoryQueries.warehouse_in(world, company_id, country_id)
	if wh.is_empty():
		return Result.fail("ERR_NO_WAREHOUSE")
	if qty > InventoryQueries.free_capacity(world, wh):
		return Result.fail("ERR_WAREHOUSE_FULL", {"free_qty": InventoryQueries.free_capacity(world, wh)})
	var q: Dictionary = MarketQueries.quote(world, ctx.content, country_id, commodity_id, qty, true)
	if not bool(q["ok"]):
		return Result.fail(str(q["error_key"]), {"max_qty": q["max_qty"]})
	if FinanceQueries.cash(world, company_id) < int(q["total"]):
		return Result.fail("ERR_NOT_ENOUGH_CASH", {"cash_cents": FinanceQueries.cash(world, company_id)})
	return Result.success(q)


func apply(world: WorldState, ctx: TickContext) -> void:
	var wh: String = InventoryQueries.warehouse_in(world, company_id, country_id)
	var q: Dictionary = MarketService.execute(world, ctx.content, country_id, commodity_id, qty, true)
	var total: int = int(q["total"])
	InventoryService.add(world, wh, commodity_id, qty, total)
	Ledger.post(world, ctx.day, company_id, "JE_PURCHASE", [Ledger.dr(Accounts.INVENTORY, total), Ledger.cr(Accounts.CASH, total)], {"commodity": commodity_id, "country": country_id})
	TradeState.of(world).log_trade({"day": ctx.day, "company": company_id, "side": "buy", "country": country_id, "commodity": commodity_id, "qty": qty, "unit_price": q["unit_price"], "total": total, "profit": 0})
	ctx.emit("trade.bought", {"country": country_id, "commodity": commodity_id, "qty": qty, "total_cents": total}, "EVT_BOUGHT", SimEvent.Importance.LOW, company_id)


func to_dict() -> Dictionary:
	return {"country": country_id, "commodity": commodity_id, "qty": qty}


func from_dict(d: Dictionary) -> void:
	country_id = SaveUtil.s(d, "country")
	commodity_id = SaveUtil.s(d, "commodity")
	qty = SaveUtil.i(d, "qty")

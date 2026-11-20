class_name OpenWarehouseCommand
extends SimCommand
## Thuê/mở kho tại một quốc gia.

const TYPE := "inventory.open_warehouse"

var country_id: String = ""


static func create(company: String, country: String) -> OpenWarehouseCommand:
	var c := OpenWarehouseCommand.new()
	c.company_id = company
	c.country_id = country
	return c


func get_type() -> String:
	return TYPE


func validate(world: WorldState, ctx: TickContext) -> Result:
	if not ctx.content.countries.has(country_id):
		return Result.fail("ERR_UNKNOWN_COUNTRY")
	if not InventoryQueries.warehouse_in(world, company_id, country_id).is_empty():
		return Result.fail("ERR_WAREHOUSE_EXISTS")
	var cost: int = Money.from_float(ctx.content.setting_f("warehouse.open_cost", 150000.0))
	if FinanceQueries.cash(world, company_id) < cost:
		return Result.fail("ERR_NOT_ENOUGH_CASH", {"cash_cents": FinanceQueries.cash(world, company_id)})
	return Result.success()


func apply(world: WorldState, ctx: TickContext) -> void:
	var cost: int = Money.from_float(ctx.content.setting_f("warehouse.open_cost", 150000.0))
	var id: String = InventoryService.create_warehouse(world, ctx, company_id, country_id)
	Ledger.post(world, ctx.day, company_id, "JE_WAREHOUSE_OPENED", [Ledger.dr(Accounts.SETUP_EXPENSE, cost), Ledger.cr(Accounts.CASH, cost)], {"country": country_id})
	ctx.emit("inventory.warehouse_opened", {"warehouse": id, "country": country_id, "cost_cents": cost}, "EVT_WAREHOUSE_OPENED", SimEvent.Importance.NORMAL, company_id)


func to_dict() -> Dictionary:
	return {"country": country_id}


func from_dict(d: Dictionary) -> void:
	country_id = SaveUtil.s(d, "country")

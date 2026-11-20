class_name TestWorld
extends RefCounted
## Tiện ích dựng Simulation cho test.

static var _content: ContentRegistry = null


static func content() -> ContentRegistry:
	if _content == null:
		var loader := ContentLoader.new()
		_content = loader.load_roots(ContentLoader.DEFAULT_ROOTS)
		assert(loader.errors.is_empty(), "Dữ liệu lỗi: %s" % [loader.errors])
	return _content


static func new_sim(seed_value: int = 42) -> Simulation:
	var sim := Simulation.create_from_content(content())
	sim.new_game("default", seed_value)
	return sim


## Hash trạng thái để so sánh tính tất định.
static func state_hash(sim: Simulation) -> String:
	return SaveService.encode({"data": sim.to_save_dict()}).sha256_text()


## Kiểm tra các bất biến kế toán/tồn kho. Trả về danh sách lỗi (rỗng nếu ổn).
static func check_invariants(sim: Simulation) -> Array[String]:
	var errs: Array[String] = []
	var w: WorldState = sim.world
	for company in CorporateQueries.company_ids(w):
		var bal: Dictionary = FinanceState.of(w).company_balances(company)
		var total: int = 0
		for k: Variant in bal:
			total += int(bal[k])
		if total != 0:
			errs.append("Sổ cái không cân (%d) cho %s" % [total, company])
		var bs: Dictionary = FinanceQueries.balance_sheet(w, sim.content, company)
		if int(bs["total_assets"]) != int(bs["total_liabilities"]) + int(bs["equity"]):
			errs.append("Tài sản != Nợ + Vốn")
		if InventoryQueries.total_cost(w, company) != FinanceQueries.balance(w, company, Accounts.INVENTORY):
			errs.append("Tồn kho (%d) != TK inventory (%d)" % [InventoryQueries.total_cost(w, company), FinanceQueries.balance(w, company, Accounts.INVENTORY)])
		if LogisticsQueries.in_transit_value(w, company) != FinanceQueries.balance(w, company, Accounts.INVENTORY_TRANSIT):
			errs.append("Hàng đi đường != TK inventory_transit")
		if TradeQueries.total_receivables(w, company) != FinanceQueries.balance(w, company, Accounts.RECEIVABLES):
			errs.append("Công nợ != TK receivables")
		if FinanceQueries.debt(w, company) != -FinanceQueries.balance(w, company, Accounts.LOANS):
			errs.append("Dư nợ != TK loans")
		for wh in InventoryQueries.warehouses_of(w, company):
			for kid in InventoryQueries.items(w, wh):
				if InventoryQueries.available(w, wh, kid) < 0 or InventoryQueries.cost_of(w, wh, kid) < 0:
					errs.append("Tồn kho âm: %s/%s" % [wh, kid])
	for cid in sim.content.country_ids:
		for kid in sim.content.commodity_ids:
			var e: Dictionary = MarketQueries.entry(w, cid, kid)
			if float(e["stock"]) < 0.0 or is_nan(float(e["price"])):
				errs.append("Thị trường lỗi: %s/%s" % [cid, kid])
	return errs

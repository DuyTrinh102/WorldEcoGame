class_name FinanceState
extends ModuleState

## company_id -> {account_id: int (debit dương)}
var balances: Dictionary = {}
## Các bút toán gần nhất: {day, company, memo, args, lines: [[acct, amount]]}
var journal: Array = []
## company_id -> dư nợ vay (cent)
var loans: Dictionary = {}
## company_id -> Array báo cáo tháng
var reports: Dictionary = {}
## company_id -> số dư tài khoản tại lần chốt kỳ trước
var last_close: Dictionary = {}


static func of(world: WorldState) -> FinanceState:
	return world.get_state("finance") as FinanceState


func company_balances(company_id: String) -> Dictionary:
	if not balances.has(company_id):
		balances[company_id] = {}
	return balances[company_id]


func to_dict() -> Dictionary:
	return {
		"balances": balances.duplicate(true),
		"journal": journal.duplicate(true),
		"loans": loans.duplicate(),
		"reports": reports.duplicate(true),
		"last_close": last_close.duplicate(true),
	}


func from_dict(d: Dictionary) -> void:
	balances = {}
	var b: Dictionary = SaveUtil.dict(d, "balances")
	for k: Variant in b:
		balances[str(k)] = SaveUtil.int_map(b[k])
	last_close = {}
	var lc: Dictionary = SaveUtil.dict(d, "last_close")
	for k: Variant in lc:
		last_close[str(k)] = SaveUtil.int_map(lc[k])
	loans = SaveUtil.int_map(SaveUtil.dict(d, "loans"))
	journal = []
	for e: Variant in SaveUtil.arr(d, "journal"):
		var ed: Dictionary = e
		var lines: Array = []
		for l: Variant in SaveUtil.arr(ed, "lines"):
			lines.append([str(l[0]), int(l[1])])
		journal.append({"day": SaveUtil.i(ed, "day"), "company": SaveUtil.s(ed, "company"), "memo": SaveUtil.s(ed, "memo"), "args": SaveUtil.dict(ed, "args"), "lines": lines})
	reports = {}
	var r: Dictionary = SaveUtil.dict(d, "reports")
	for k: Variant in r:
		var list: Array = []
		for rep: Variant in r[k]:
			list.append(FinanceState.report_from_dict(rep as Dictionary))
		reports[str(k)] = list


static func report_from_dict(d: Dictionary) -> Dictionary:
	return {
		"period": SaveUtil.s(d, "period"),
		"day": SaveUtil.i(d, "day"),
		"lines": SaveUtil.int_map(SaveUtil.dict(d, "lines")),
		"revenue": SaveUtil.i(d, "revenue"),
		"cogs": SaveUtil.i(d, "cogs"),
		"gross_profit": SaveUtil.i(d, "gross_profit"),
		"operating_expenses": SaveUtil.i(d, "operating_expenses"),
		"net_income": SaveUtil.i(d, "net_income"),
		"cash": SaveUtil.i(d, "cash"),
		"total_assets": SaveUtil.i(d, "total_assets"),
		"total_liabilities": SaveUtil.i(d, "total_liabilities"),
		"equity": SaveUtil.i(d, "equity"),
	}

class_name FinanceQueries
extends RefCounted
## API chỉ-đọc: số dư, báo cáo kết quả kinh doanh, bảng cân đối, hạn mức tín dụng.
## Mọi số liệu đều suy ra từ sổ cái (nguồn sự thật duy nhất).


static func balance(world: WorldState, company_id: String, account_id: String) -> int:
	return int(FinanceState.of(world).company_balances(company_id).get(account_id, 0))


static func cash(world: WorldState, company_id: String) -> int:
	return balance(world, company_id, Accounts.CASH)


static func debt(world: WorldState, company_id: String) -> int:
	return int(FinanceState.of(world).loans.get(company_id, 0))


## Báo cáo kết quả kinh doanh từ chênh lệch số dư (now - since). Doanh thu/chi phí trả về số dương.
static func income_statement(content: ContentRegistry, now: Dictionary, since: Dictionary) -> Dictionary:
	var lines: Dictionary = {}
	var revenue: int = 0
	var cogs: int = 0
	var opex: int = 0
	for acc_id in content.account_ids:
		var acc: AccountDef = content.account(acc_id)
		if acc.is_balance_sheet():
			continue
		var delta: int = int(now.get(acc_id, 0)) - int(since.get(acc_id, 0))
		if acc.kind == AccountDef.Kind.REVENUE:
			lines[acc_id] = -delta
			revenue += -delta
		else:
			lines[acc_id] = delta
			if acc_id == Accounts.COGS:
				cogs += delta
			else:
				opex += delta
	return {
		"lines": lines,
		"revenue": revenue,
		"cogs": cogs,
		"gross_profit": revenue - cogs,
		"operating_expenses": opex,
		"net_income": revenue - cogs - opex,
	}


## Kết quả kinh doanh từ đầu tháng đến nay.
static func month_to_date(world: WorldState, content: ContentRegistry, company_id: String) -> Dictionary:
	var st: FinanceState = FinanceState.of(world)
	return income_statement(content, st.company_balances(company_id), st.last_close.get(company_id, {}))


## Kết quả kinh doanh lũy kế từ khi thành lập.
static func all_time(world: WorldState, content: ContentRegistry, company_id: String) -> Dictionary:
	return income_statement(content, FinanceState.of(world).company_balances(company_id), {})


## Bảng cân đối kế toán. Tài sản = Nợ phải trả + Vốn chủ sở hữu.
static func balance_sheet(world: WorldState, content: ContentRegistry, company_id: String) -> Dictionary:
	var bal: Dictionary = FinanceState.of(world).company_balances(company_id)
	var assets: Dictionary = {}
	var liabilities: Dictionary = {}
	var total_assets: int = 0
	var total_liabilities: int = 0
	var capital: int = 0
	var pnl_debit_sum: int = 0
	for acc_id in content.account_ids:
		var acc: AccountDef = content.account(acc_id)
		var v: int = int(bal.get(acc_id, 0))
		match acc.kind:
			AccountDef.Kind.ASSET:
				assets[acc_id] = v
				total_assets += v
			AccountDef.Kind.LIABILITY:
				liabilities[acc_id] = -v
				total_liabilities += -v
			AccountDef.Kind.EQUITY:
				capital += -v
			_:
				pnl_debit_sum += v
	var retained: int = -pnl_debit_sum
	return {
		"assets": assets,
		"total_assets": total_assets,
		"liabilities": liabilities,
		"total_liabilities": total_liabilities,
		"capital": capital,
		"retained_earnings": retained,
		"equity": capital + retained,
	}


static func net_worth(world: WorldState, content: ContentRegistry, company_id: String) -> int:
	return int(balance_sheet(world, content, company_id)["equity"])


static func credit_limit(world: WorldState, content: ContentRegistry, company_id: String) -> int:
	var base: int = Money.from_float(content.setting_f("finance.max_loan_base", 3_000_000))
	var ratio: float = content.setting_f("finance.max_loan_equity_ratio", 1.0)
	var equity: int = net_worth(world, content, company_id)
	return maxi(base, IntMath.mul_ratio(maxi(equity, 0), ratio))


static func available_credit(world: WorldState, content: ContentRegistry, company_id: String) -> int:
	return maxi(0, credit_limit(world, content, company_id) - debt(world, company_id))


static func reports(world: WorldState, company_id: String) -> Array:
	return FinanceState.of(world).reports.get(company_id, [])


static func journal(world: WorldState, company_id: String, limit: int = 50) -> Array:
	var out: Array = []
	var j: Array = FinanceState.of(world).journal
	for i in range(j.size() - 1, -1, -1):
		if str(j[i]["company"]) == company_id:
			out.append(j[i])
			if out.size() >= limit:
				break
	return out

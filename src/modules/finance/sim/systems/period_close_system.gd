class_name PeriodCloseSystem
extends SimSystem
## Chốt sổ cuối tháng: lập báo cáo kết quả kinh doanh của tháng + ảnh chụp bảng cân đối.

const MAX_REPORTS: int = 120


func get_id() -> String:
	return "finance.period_close"


func get_phase() -> SimPhase.Phase:
	return SimPhase.Phase.PERIOD_CLOSE


func get_frequency() -> SimSystem.Frequency:
	return SimSystem.Frequency.MONTHLY


func run(world: WorldState, ctx: TickContext) -> void:
	var st: FinanceState = FinanceState.of(world)
	for company_id in CorporateQueries.company_ids(world):
		var now: Dictionary = st.company_balances(company_id)
		var income: Dictionary = FinanceQueries.income_statement(ctx.content, now, st.last_close.get(company_id, {}))
		var bs: Dictionary = FinanceQueries.balance_sheet(world, ctx.content, company_id)
		var report: Dictionary = income.duplicate(true)
		report["period"] = GameDate.period_key(ctx.day)
		report["day"] = ctx.day
		report["cash"] = FinanceQueries.cash(world, company_id)
		report["total_assets"] = bs["total_assets"]
		report["total_liabilities"] = bs["total_liabilities"]
		report["equity"] = bs["equity"]
		var list: Array = st.reports.get(company_id, [])
		list.append(report)
		if list.size() > MAX_REPORTS:
			list.pop_front()
		st.reports[company_id] = list
		st.last_close[company_id] = now.duplicate()
		ctx.emit("finance.period_closed", {
			"period": report["period"],
			"revenue_cents": report["revenue"],
			"net_income_cents": report["net_income"],
		}, "EVT_PERIOD_CLOSED", SimEvent.Importance.HIGH, company_id)

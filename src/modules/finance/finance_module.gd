class_name FinanceModule
extends SimModule
## Sổ cái kép, khoản vay, lãi, chốt kỳ và báo cáo tài chính.


func get_id() -> String:
	return "finance"


func get_dependencies() -> Array[String]:
	return ["corporate"]


func register(ctx: ModuleContext) -> void:
	ctx.register_state(FinanceState)
	ctx.register_system(InterestSystem.new())
	ctx.register_system(PeriodCloseSystem.new())
	ctx.register_command(TakeLoanCommand.TYPE, TakeLoanCommand)
	ctx.register_command(RepayLoanCommand.TYPE, RepayLoanCommand)
	ctx.register_ui_screen("finance", "res://src/modules/finance/ui/finance_screen.gd", "NAV_FINANCE", 50)


func on_new_game(world: WorldState, ctx: TickContext, scenario: Dictionary) -> void:
	var st: FinanceState = FinanceState.of(world)
	var start_cash: int = Money.from_float(float(scenario.get("start_cash", 1_000_000)))
	for company_id in CorporateQueries.company_ids(world):
		st.balances[company_id] = {}
		st.loans[company_id] = 0
		st.reports[company_id] = []
		Ledger.post(world, ctx.day, company_id, "JE_INITIAL_CAPITAL", [
			Ledger.dr(Accounts.CASH, start_cash),
			Ledger.cr(Accounts.CAPITAL, start_cash),
		])
		st.last_close[company_id] = st.company_balances(company_id).duplicate()

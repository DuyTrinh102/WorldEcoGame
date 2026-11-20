class_name InterestSystem
extends SimSystem
## Cuối tháng: trả lãi vay ngân hàng và lãi thấu chi khi tiền mặt âm.


func get_id() -> String:
	return "finance.interest"


func get_phase() -> SimPhase.Phase:
	return SimPhase.Phase.FINANCE


func get_frequency() -> SimSystem.Frequency:
	return SimSystem.Frequency.MONTHLY


func run(world: WorldState, ctx: TickContext) -> void:
	var loan_rate: float = ctx.content.setting_f("finance.loan_rate_annual", 0.08)
	var overdraft_rate: float = ctx.content.setting_f("finance.overdraft_rate_annual", 0.18)
	for company_id in CorporateQueries.company_ids(world):
		var debt: int = FinanceQueries.debt(world, company_id)
		var interest: int = IntMath.mul_ratio(debt, loan_rate / 12.0)
		var cash: int = FinanceQueries.cash(world, company_id)
		var overdraft: int = IntMath.mul_ratio(-cash, overdraft_rate / 12.0) if cash < 0 else 0
		if interest + overdraft > 0:
			Ledger.post(world, ctx.day, company_id, "JE_INTEREST", [
				Ledger.dr(Accounts.INTEREST_EXPENSE, interest + overdraft),
				Ledger.cr(Accounts.CASH, interest + overdraft),
			])
		if FinanceQueries.cash(world, company_id) < 0:
			ctx.emit("finance.cash_negative", {"cash_cents": FinanceQueries.cash(world, company_id)}, "EVT_CASH_NEGATIVE", SimEvent.Importance.HIGH, company_id)

class_name RepayLoanCommand
extends SimCommand
## Trả bớt nợ vay.

const TYPE := "finance.repay_loan"

var amount: int = 0


static func create(company: String, amount_cents: int) -> RepayLoanCommand:
	var c := RepayLoanCommand.new()
	c.company_id = company
	c.amount = amount_cents
	return c


func get_type() -> String:
	return TYPE


func validate(world: WorldState, _ctx: TickContext) -> Result:
	if amount <= 0:
		return Result.fail("ERR_AMOUNT_POSITIVE")
	if amount > FinanceQueries.debt(world, company_id):
		return Result.fail("ERR_REPAY_EXCEEDS_DEBT")
	if amount > FinanceQueries.cash(world, company_id):
		return Result.fail("ERR_NOT_ENOUGH_CASH", {"cash_cents": FinanceQueries.cash(world, company_id)})
	return Result.success()


func apply(world: WorldState, ctx: TickContext) -> void:
	var st: FinanceState = FinanceState.of(world)
	st.loans[company_id] = int(st.loans.get(company_id, 0)) - amount
	Ledger.post(world, ctx.day, company_id, "JE_LOAN_REPAID", [Ledger.dr(Accounts.LOANS, amount), Ledger.cr(Accounts.CASH, amount)])
	ctx.emit("finance.loan_repaid", {"amount_cents": amount}, "EVT_LOAN_REPAID", SimEvent.Importance.NORMAL, company_id)


func to_dict() -> Dictionary:
	return {"amount": amount}


func from_dict(d: Dictionary) -> void:
	amount = SaveUtil.i(d, "amount")

class_name TakeLoanCommand
extends SimCommand
## Vay ngân hàng (NPC) trong hạn mức tín dụng.

const TYPE := "finance.take_loan"

var amount: int = 0  # cent


static func create(company: String, amount_cents: int) -> TakeLoanCommand:
	var c := TakeLoanCommand.new()
	c.company_id = company
	c.amount = amount_cents
	return c


func get_type() -> String:
	return TYPE


func validate(world: WorldState, ctx: TickContext) -> Result:
	if amount <= 0:
		return Result.fail("ERR_AMOUNT_POSITIVE")
	var available: int = FinanceQueries.available_credit(world, ctx.content, company_id)
	if amount > available:
		return Result.fail("ERR_CREDIT_LIMIT", {"available_cents": available})
	return Result.success()


func apply(world: WorldState, ctx: TickContext) -> void:
	var st: FinanceState = FinanceState.of(world)
	st.loans[company_id] = int(st.loans.get(company_id, 0)) + amount
	Ledger.post(world, ctx.day, company_id, "JE_LOAN_TAKEN", [Ledger.dr(Accounts.CASH, amount), Ledger.cr(Accounts.LOANS, amount)])
	ctx.emit("finance.loan_taken", {"amount_cents": amount}, "EVT_LOAN_TAKEN", SimEvent.Importance.NORMAL, company_id)


func to_dict() -> Dictionary:
	return {"amount": amount}


func from_dict(d: Dictionary) -> void:
	amount = SaveUtil.i(d, "amount")

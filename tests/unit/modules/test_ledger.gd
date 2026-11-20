extends TestCase

var sim: Simulation
var co: String


func before_each() -> void:
	sim = TestWorld.new_sim()
	co = sim.world.player_company_id


func test_initial_capital_posted() -> void:
	assert_eq(FinanceQueries.cash(sim.world, co), Money.from_units(5_000_000))
	var bs: Dictionary = FinanceQueries.balance_sheet(sim.world, sim.content, co)
	assert_eq(bs["capital"], Money.from_units(5_000_000))
	assert_eq(bs["total_assets"], bs["equity"])


func test_unbalanced_entry_rejected() -> void:
	var before: int = FinanceQueries.cash(sim.world, co)
	# push_error là kỳ vọng ở đây.
	var ok: bool = Ledger.post(sim.world, sim.world.day, co, "TEST", [Ledger.dr(Accounts.CASH, 100), Ledger.cr(Accounts.REVENUE, 99)])
	assert_false(ok)
	assert_eq(FinanceQueries.cash(sim.world, co), before)


func test_income_statement_from_entries() -> void:
	Ledger.post(sim.world, sim.world.day, co, "TEST", [Ledger.dr(Accounts.RECEIVABLES, 1000), Ledger.cr(Accounts.REVENUE, 1000), Ledger.dr(Accounts.COGS, 600), Ledger.cr(Accounts.INVENTORY, 600)])
	var inc: Dictionary = FinanceQueries.month_to_date(sim.world, sim.content, co)
	assert_eq(inc["revenue"], 1000)
	assert_eq(inc["cogs"], 600)
	assert_eq(inc["gross_profit"], 400)
	assert_eq(inc["net_income"], 400)


func test_loan_take_and_repay() -> void:
	assert_ok(sim.submit(TakeLoanCommand.create(co, Money.from_units(1_000_000))))
	assert_eq(FinanceQueries.debt(sim.world, co), Money.from_units(1_000_000))
	assert_eq(FinanceQueries.cash(sim.world, co), Money.from_units(6_000_000))
	assert_err(sim.submit(TakeLoanCommand.create(co, Money.from_units(100_000_000))), "ERR_CREDIT_LIMIT")
	assert_err(sim.submit(RepayLoanCommand.create(co, Money.from_units(2_000_000))), "ERR_REPAY_EXCEEDS_DEBT")
	assert_ok(sim.submit(RepayLoanCommand.create(co, Money.from_units(400_000))))
	assert_eq(FinanceQueries.debt(sim.world, co), Money.from_units(600_000))
	assert_eq(TestWorld.check_invariants(sim), [] as Array[String])


func test_monthly_interest_and_period_close() -> void:
	sim.submit(TakeLoanCommand.create(co, Money.from_units(1_200_000)))
	sim.step_days(31)  # chạy qua cuối tháng 1
	# lãi 8%/năm / 12 trên 1.2M = 8,000 + phí kho tháng
	var reports: Array = FinanceQueries.reports(sim.world, co)
	assert_eq(reports.size(), 1)
	assert_eq(reports[0]["period"], "2027-01")
	assert_eq(int(reports[0]["lines"][Accounts.INTEREST_EXPENSE]), Money.from_units(8_000))
	assert_true(int(reports[0]["net_income"]) < 0)

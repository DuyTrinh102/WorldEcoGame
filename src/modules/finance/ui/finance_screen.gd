extends ScreenBase
## Trung tâm tài chính: bảng cân đối, kết quả kinh doanh, vay vốn, biểu đồ, nhật ký bút toán.

var _content_box: VBoxContainer
var _amount: SpinBox


func setup() -> void:
	var root := UI.vbox(12)
	add_child(root)
	root.add_child(header("FIN_TITLE", "FIN_SUBTITLE"))
	_content_box = UI.vbox(14)
	root.add_child(UI.scroll(_content_box))
	_amount = SpinBox.new()
	_amount.min_value = 0
	_amount.max_value = 100_000_000
	_amount.step = 100_000
	_amount.value = 1_000_000
	_amount.prefix = "$"
	_amount.custom_minimum_size = Vector2(170, 0)


func refresh() -> void:
	var w: WorldState = world()
	var c: ContentRegistry = content()
	var co: String = company()
	if _amount.get_parent() != null:
		_amount.get_parent().remove_child(_amount)
	UI.clear(_content_box)
	var top := UI.hbox(14)
	top.add_child(_balance_sheet(w, c, co))
	top.add_child(_income_statement(w, c, co))
	_content_box.add_child(top)
	var mid := UI.hbox(14)
	mid.add_child(_loans(w, c, co))
	mid.add_child(_chart(w, co))
	_content_box.add_child(mid)
	_content_box.add_child(_journal(w, co))


func _section(title_key: String) -> Array:
	var card := UI.card()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(8)
	card.add_child(v)
	v.add_child(UI.label(Loc.t(title_key), "SubHeaderLabel"))
	return [card, v]


func _line(g: GridContainer, text: String, cents: int, strong: bool = false, color: Color = AppTheme.TEXT) -> void:
	g.add_child(UI.bold(text, color) if strong else UI.label(text, "", AppTheme.MUTED if not strong else color))
	g.add_child(UI.right(UI.bold(Fmt.money(cents), color) if strong else UI.label(Fmt.money(cents))))


func _balance_sheet(w: WorldState, c: ContentRegistry, co: String) -> PanelContainer:
	var s: Array = _section("FIN_BALANCE_SHEET")
	var bs: Dictionary = FinanceQueries.balance_sheet(w, c, co)
	var g := UI.grid(2, 30, 3)
	g.add_child(UI.label(Loc.t("FIN_ASSETS"), "MutedLabel"))
	g.add_child(Control.new())
	for acc: String in bs["assets"]:
		if int(bs["assets"][acc]) != 0:
			_line(g, "  " + Loc.t(c.account(acc).name_key), int(bs["assets"][acc]))
	_line(g, Loc.t("FIN_TOTAL_ASSETS"), int(bs["total_assets"]), true)
	g.add_child(UI.label(Loc.t("FIN_LIABILITIES"), "MutedLabel"))
	g.add_child(Control.new())
	for acc: String in bs["liabilities"]:
		_line(g, "  " + Loc.t(c.account(acc).name_key), int(bs["liabilities"][acc]))
	_line(g, "  " + Loc.t("ACC_CAPITAL"), int(bs["capital"]))
	_line(g, "  " + Loc.t("FIN_RETAINED"), int(bs["retained_earnings"]), false)
	_line(g, Loc.t("FIN_TOTAL_EQUITY"), int(bs["equity"]), true, Fmt.signed_color(float(bs["retained_earnings"])))
	(s[1] as VBoxContainer).add_child(g)
	return s[0]


func _income_statement(w: WorldState, c: ContentRegistry, co: String) -> PanelContainer:
	var s: Array = _section("FIN_INCOME")
	var mtd: Dictionary = FinanceQueries.month_to_date(w, c, co)
	var reports: Array = FinanceQueries.reports(w, co)
	var last: Dictionary = reports[-1] if not reports.is_empty() else {}
	var total: Dictionary = FinanceQueries.all_time(w, c, co)
	var g := UI.grid(4, 24, 3)
	g.add_child(Control.new())
	for h: String in ["FIN_COL_MTD", "FIN_COL_LAST", "FIN_COL_TOTAL"]:
		g.add_child(UI.right(UI.label(Loc.t(h) if h != "FIN_COL_LAST" or last.is_empty() else Loc.t(h) + " (" + str(last["period"]) + ")", "MutedLabel")))
	var rows: Array = [["FIN_REVENUE", "revenue"], ["FIN_COGS", "cogs"], ["FIN_GROSS", "gross_profit"]]
	for acc_id in c.account_ids:
		var acc: AccountDef = c.account(acc_id)
		if acc.kind == AccountDef.Kind.EXPENSE and acc_id != Accounts.COGS:
			rows.append([acc.name_key, "line:" + acc_id])
	rows.append(["FIN_NET_INCOME", "net_income"])
	for r: Array in rows:
		var key: String = r[1]
		var strong: bool = key in ["gross_profit", "net_income"]
		g.add_child(UI.bold(Loc.t(r[0])) if strong else UI.label(Loc.t(r[0]), "", AppTheme.MUTED))
		for src: Dictionary in [mtd, last, total]:
			var v: int = 0
			if not src.is_empty():
				v = int(src["lines"].get(key.substr(5), 0)) if key.begins_with("line:") else int(src[key])
			var color: Color = Fmt.signed_color(float(v)) if strong else AppTheme.TEXT
			g.add_child(UI.right(UI.bold(Fmt.money(v, true), color) if strong else UI.label(Fmt.money(v, true))))
	(s[1] as VBoxContainer).add_child(g)
	var note := UI.label(Loc.t("FIN_PROFIT_VS_CASH"), "MutedLabel")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	(s[1] as VBoxContainer).add_child(note)
	return s[0]


func _loans(w: WorldState, c: ContentRegistry, co: String) -> PanelContainer:
	var s: Array = _section("FIN_LOANS")
	var v: VBoxContainer = s[1]
	var g := UI.grid(2, 30, 3)
	_line(g, Loc.t("FIN_DEBT"), FinanceQueries.debt(w, co))
	_line(g, Loc.t("FIN_CREDIT_LIMIT"), FinanceQueries.credit_limit(w, c, co))
	_line(g, Loc.t("FIN_AVAILABLE_CREDIT"), FinanceQueries.available_credit(w, c, co), true, AppTheme.GOOD)
	g.add_child(UI.label(Loc.t("FIN_RATE"), "MutedLabel"))
	g.add_child(UI.right(UI.label(Loc.t("FIN_RATE_VALUE", {"loan": "%.0f" % (c.setting_f("finance.loan_rate_annual") * 100), "overdraft": "%.0f" % (c.setting_f("finance.overdraft_rate_annual") * 100)}))))
	v.add_child(g)
	var row := UI.hbox(6)
	row.add_child(_amount)
	row.add_child(UI.button(Loc.t("BTN_BORROW"), func() -> void:
		if main.submit(TakeLoanCommand.create(company(), Money.from_float(_amount.value))).ok:
			main.toast(Loc.t("TOAST_BORROWED"), AppTheme.GOOD), "AccentButton"))
	row.add_child(UI.button(Loc.t("BTN_REPAY"), func() -> void:
		if main.submit(RepayLoanCommand.create(company(), Money.from_float(_amount.value))).ok:
			main.toast(Loc.t("TOAST_REPAID"), AppTheme.GOOD)))
	v.add_child(row)
	var receivables: Array[Dictionary] = TradeQueries.receivables_of(w, co)
	if not receivables.is_empty():
		v.add_child(UI.label(Loc.t("FIN_RECEIVABLES", {"n": receivables.size(), "total": Fmt.money(TradeQueries.total_receivables(w, co), true), "next": Fmt.date(int(receivables[0]["due_day"]))}), "MutedLabel"))
	return s[0]


func _chart(w: WorldState, co: String) -> PanelContainer:
	var s: Array = _section("FIN_CHART")
	var reports: Array = FinanceQueries.reports(w, co)
	var net: Array = []
	var cash: Array = []
	for r: Dictionary in reports.slice(maxi(0, reports.size() - 24)):
		net.append(Money.to_float(int(r["net_income"])))
		cash.append(Money.to_float(int(r["cash"])))
	var chart := LineChart.new()
	chart.zero_line = true
	chart.custom_minimum_size = Vector2(360, 180)
	chart.value_formatter = func(v: float) -> String: return Money.format(Money.from_float(v), true)
	chart.set_series([
		{"values": cash, "color": AppTheme.INFO, "label": Loc.t("FIN_CHART_CASH")},
		{"values": net, "color": AppTheme.ACCENT, "label": Loc.t("FIN_CHART_NET")},
	] as Array[Dictionary])
	(s[1] as VBoxContainer).add_child(chart)
	return s[0]


func _journal(w: WorldState, co: String) -> PanelContainer:
	var s: Array = _section("FIN_JOURNAL")
	var g := UI.grid(3, 24, 3)
	for e: Dictionary in FinanceQueries.journal(w, co, 15):
		g.add_child(UI.label(Fmt.date(int(e["day"])), "MutedLabel"))
		var memo := UI.label(Loc.t(str(e["memo"]), Fmt.args(e["args"])))
		memo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(memo)
		var cash_delta: int = 0
		for l: Array in e["lines"]:
			if str(l[0]) == Accounts.CASH:
				cash_delta += int(l[1])
		g.add_child(UI.right(UI.label(Loc.t("FIN_CASH_DELTA", {"amount": Fmt.money(cash_delta, true)}) if cash_delta != 0 else Loc.t("FIN_NO_CASH"), "", Fmt.signed_color(float(cash_delta)))))
	(s[1] as VBoxContainer).add_child(g)
	return s[0]

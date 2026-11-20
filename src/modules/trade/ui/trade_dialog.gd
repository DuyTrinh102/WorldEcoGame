class_name TradeDialog
extends FormDialog
## Hộp thoại mua/bán hàng hóa với thị trường một quốc gia (xem trước giá có trượt giá).

var is_buy: bool = true
var country_id: String = ""
var commodity_id: String = ""
var wh: String = ""
var qty_box: SpinBox
var _unit: Label = UI.label("")
var _total: Label = UI.label("")
var _extra: Label = UI.label("")
var _note: Label


static func create(p_main: MainUI, buy: bool, country: String, commodity: String) -> TradeDialog:
	var d := TradeDialog.new()
	d.is_buy = buy
	d.country_id = country
	d.commodity_id = commodity
	var key: String = "DLG_BUY_TITLE" if buy else "DLG_SELL_TITLE"
	d.init_dialog(p_main, Loc.t(key, {"commodity": Fmt.commodity(commodity), "country": Fmt.country(country)}), Loc.t("BTN_BUY" if buy else "BTN_SELL"))
	d._build()
	return d


func _build() -> void:
	var w: WorldState = main.session.world()
	var content: ContentRegistry = main.session.content
	var co: String = main.session.company_id()
	wh = InventoryQueries.warehouse_in(w, co, country_id)
	var price: float = MarketQueries.price(w, country_id, commodity_id)
	var info := UI.grid(2, 24, 4)
	FormDialog.info_row(info, "DLG_MARKET_PRICE", UI.bold(Fmt.price(price) + "/t"))
	FormDialog.info_row(info, "DLG_WORLD_PRICE", UI.label(Fmt.price(MarketQueries.world_price(w, commodity_id)) + "/t"))
	var have: int = InventoryQueries.available(w, wh, commodity_id) if not wh.is_empty() else 0
	var stock_text: String = Fmt.qty(have)
	if have > 0:
		stock_text += "  (" + Loc.t("DLG_AVG_COST", {"cost": Fmt.unit_price(InventoryQueries.avg_cost(w, wh, commodity_id))}) + ")"
	FormDialog.info_row(info, "DLG_YOUR_STOCK", UI.label(stock_text))
	FormDialog.info_row(info, "DLG_CASH", UI.label(Fmt.money(FinanceQueries.cash(w, co), true)))
	body.add_child(info)
	body.add_child(UI.sep())
	var max_t: float
	if is_buy:
		var free_t: float = Quantity.to_float(InventoryQueries.free_capacity(w, wh)) if not wh.is_empty() else 0.0
		var market_max: float = Quantity.to_float(int(MarketQueries.quote(w, content, country_id, commodity_id, 1000, true)["max_qty"]))
		var afford: float = maxf(0.0, Money.to_float(FinanceQueries.cash(w, co)) / (price * 1.05))
		max_t = floorf(minf(minf(free_t, market_max), afford))
	else:
		max_t = Quantity.to_float(have)
	var row := UI.hbox(6)
	row.add_child(UI.label(Loc.t("DLG_QUANTITY")))
	qty_box = FormDialog.qty_input(max_t, minf(max_t, 500.0) if is_buy else max_t, update_preview)
	row.add_child(qty_box)
	for preset: float in [100.0, 1000.0]:
		row.add_child(UI.button("%s t" % Money.group_thousands(int(preset)), func() -> void: qty_box.value = minf(preset, qty_box.max_value)))
	row.add_child(UI.button(Loc.t("BTN_MAX"), func() -> void: qty_box.value = qty_box.max_value))
	body.add_child(row)
	body.add_child(UI.label(Loc.t("DLG_MAX_QTY", {"qty": Fmt.qty(Quantity.from_float(max_t))}), "MutedLabel"))
	var preview := UI.grid(2, 24, 4)
	FormDialog.info_row(preview, "DLG_EXEC_PRICE", _unit)
	FormDialog.info_row(preview, "DLG_TOTAL_BUY" if is_buy else "DLG_TOTAL_SELL", _total)
	FormDialog.info_row(preview, "DLG_CASH_AFTER" if is_buy else "DLG_EST_PROFIT", _extra)
	body.add_child(preview)
	_note = UI.wrap_label(Loc.t("DLG_NOTE_BUY" if is_buy else "DLG_NOTE_SELL", {"days": content.setting_i("finance.receivable_days", 30)}), 440)
	body.add_child(_note)
	finish_layout()


func update_preview() -> void:
	if qty_box == null:
		return
	var w: WorldState = main.session.world()
	var q: int = Quantity.from_float(qty_box.value)
	if q <= 0:
		_unit.text = "-"
		_total.text = "-"
		_extra.text = "-"
		return
	var quote: Dictionary = MarketQueries.quote(w, main.session.content, country_id, commodity_id, q, is_buy)
	_unit.text = Fmt.unit_price(int(quote["unit_price"])) + "/t"
	_total.text = Fmt.money(int(quote["total"]))
	if is_buy:
		var after: int = FinanceQueries.cash(w, main.session.company_id()) - int(quote["total"])
		_extra.text = Fmt.money(after, true)
		_extra.add_theme_color_override("font_color", AppTheme.BAD if after < 0 else AppTheme.TEXT)
	else:
		var cost: int = IntMath.mul_div(InventoryQueries.cost_of(w, wh, commodity_id), q, maxi(1, InventoryQueries.available(w, wh, commodity_id)))
		var profit: int = int(quote["total"]) - cost
		_extra.text = Fmt.money(profit, true)
		_extra.add_theme_color_override("font_color", Fmt.signed_color(float(profit)))


func build_command() -> SimCommand:
	var q: int = Quantity.from_float(qty_box.value)
	var co: String = main.session.company_id()
	if is_buy:
		return BuyCommand.create(co, country_id, commodity_id, q)
	return SellCommand.create(co, wh, commodity_id, q)


func on_success(_r: Result) -> void:
	var key: String = "TOAST_BOUGHT" if is_buy else "TOAST_SOLD"
	main.toast(Loc.t(key, {"qty": Fmt.qty(Quantity.from_float(qty_box.value)), "commodity": Fmt.commodity(commodity_id)}), AppTheme.GOOD)

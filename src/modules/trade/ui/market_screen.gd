extends ScreenBase
## Sàn giao dịch: bảng giá hàng hóa × quốc gia, biểu đồ lịch sử, mua/bán.

var _cells: Dictionary = {}      # "country/commodity" -> Button
var _world_cells: Dictionary = {} # commodity -> Label
var _sel_country: String = ""
var _sel_commodity: String = "coffee"
var _detail_title: Label
var _detail_stats: GridContainer
var _chart: LineChart
var _actions: HBoxContainer


func setup() -> void:
	var root := UI.vbox(12)
	add_child(root)
	root.add_child(header("MARKET_TITLE", "MARKET_SUBTITLE"))
	var table_card := UI.card()
	var countries: Array[String] = content().country_ids
	var g := UI.grid(countries.size() + 2, 6, 4)
	g.add_child(UI.label(Loc.t("COL_COMMODITY"), "MutedLabel"))
	g.add_child(UI.right(UI.label(Loc.t("COL_WORLD"), "MutedLabel")))
	for cid in countries:
		var h := UI.label(Fmt.country(cid), "MutedLabel")
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.custom_minimum_size = Vector2(84, 0)
		g.add_child(h)
	for kid in content().commodity_ids:
		var name_box := UI.hbox(6)
		name_box.add_child(UI.color_dot(content().commodity(kid).color, 9))
		name_box.add_child(UI.label(Fmt.commodity(kid)))
		name_box.custom_minimum_size = Vector2(150, 0)
		g.add_child(name_box)
		var wl := UI.right(UI.bold("-", AppTheme.MUTED, 14))
		wl.custom_minimum_size = Vector2(70, 0)
		g.add_child(wl)
		_world_cells[kid] = wl
		for cid in countries:
			var b := UI.button("-", _select.bind(cid, kid), "CellButton")
			b.toggle_mode = true
			b.custom_minimum_size = Vector2(84, 0)
			g.add_child(b)
			_cells["%s/%s" % [cid, kid]] = b
	table_card.add_child(g)
	root.add_child(table_card)
	root.add_child(UI.label(Loc.t("MARKET_LEGEND"), "MutedLabel"))
	var detail := UI.card()
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var dv := UI.hbox(18)
	detail.add_child(dv)
	var left := UI.vbox(8)
	left.custom_minimum_size = Vector2(300, 0)
	_detail_title = UI.label("", "SubHeaderLabel")
	left.add_child(_detail_title)
	_detail_stats = UI.grid(2, 18, 4)
	left.add_child(_detail_stats)
	_actions = UI.hbox(6)
	left.add_child(_actions)
	dv.add_child(left)
	_chart = LineChart.new()
	_chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dv.add_child(_chart)
	root.add_child(detail)


func _select(cid: String, kid: String) -> void:
	_sel_country = cid
	_sel_commodity = kid
	main.select_country(cid)
	refresh()


func refresh() -> void:
	var w: WorldState = world()
	if _sel_country.is_empty():
		_sel_country = main.selected_country
	for kid in content().commodity_ids:
		var wp: float = MarketQueries.world_price(w, kid)
		(_world_cells[kid] as Label).text = Fmt.price(wp)
		for cid in content().country_ids:
			var b: Button = _cells["%s/%s" % [cid, kid]]
			var p: float = MarketQueries.price(w, cid, kid)
			var ratio: float = p / maxf(wp, 0.01)
			b.text = Fmt.price(p)
			var color: Color = AppTheme.TEXT
			if ratio < 0.95:
				color = AppTheme.GOOD
			elif ratio > 1.05:
				color = AppTheme.BAD
			b.add_theme_color_override("font_color", color)
			b.add_theme_color_override("font_hover_color", color)
			b.add_theme_color_override("font_pressed_color", color)
			b.set_pressed_no_signal(cid == _sel_country and kid == _sel_commodity)
			b.tooltip_text = Loc.t("TIP_VS_WORLD", {"pct": Fmt.pct(ratio - 1.0), "world": Fmt.price(wp)})
	_refresh_detail()


func _refresh_detail() -> void:
	var w: WorldState = world()
	var cid: String = _sel_country
	var kid: String = _sel_commodity
	_detail_title.text = "%s — %s" % [Fmt.commodity(kid), Fmt.country(cid)]
	UI.clear(_detail_stats)
	var e: Dictionary = MarketQueries.entry(w, cid, kid)
	var p: float = float(e["price"])
	var cover: float = float(e["stock"]) / maxf(float(e["scale"]) / 365.0, 0.001)
	var rows: Array = [
		["DLG_MARKET_PRICE", Fmt.price(p) + "/t"],
		["DLG_WORLD_PRICE", Fmt.price(MarketQueries.world_price(w, kid)) + "/t"],
		["MARKET_MONTH_CHANGE", Fmt.pct(MarketQueries.month_change(w, cid, kid))],
		["MARKET_STOCK", Loc.t("MARKET_STOCK_VALUE", {"qty": Fmt.qty(Quantity.from_float(float(e["stock"]))), "days": int(cover)})],
		["MARKET_PRODUCTION", Fmt.qty(Quantity.from_float(float(e["base_prod"]))) + Loc.t("UNIT_PER_YEAR")],
		["MARKET_CONSUMPTION", Fmt.qty(Quantity.from_float(float(e["base_cons"]))) + Loc.t("UNIT_PER_YEAR")],
	]
	var wh: String = InventoryQueries.warehouse_in(w, company(), cid)
	if not wh.is_empty():
		rows.append(["DLG_YOUR_STOCK", Fmt.qty(InventoryQueries.available(w, wh, kid))])
	for r: Array in rows:
		_detail_stats.add_child(UI.label(Loc.t(r[0]), "MutedLabel"))
		_detail_stats.add_child(UI.label(r[1]))
	UI.clear(_actions)
	if wh.is_empty():
		_actions.add_child(UI.button(Loc.t("BTN_OPEN_WAREHOUSE", {"cost": Fmt.money(Money.from_float(content().setting_f("warehouse.open_cost", 150000.0)), true)}), main.open_warehouse.bind(cid), "AccentButton"))
	else:
		_actions.add_child(UI.button(Loc.t("BTN_BUY"), main.open_trade.bind(true, cid, kid), "AccentButton"))
		var sell := UI.button(Loc.t("BTN_SELL"), main.open_trade.bind(false, cid, kid))
		sell.disabled = InventoryQueries.available(w, wh, kid) <= 0
		_actions.add_child(sell)
	var series: Array[Dictionary] = [
		{"values": MarketQueries.history(w, MarketState.WORLD_KEY, kid), "color": AppTheme.MUTED, "label": Loc.t("COL_WORLD")},
		{"values": MarketQueries.history(w, cid, kid), "color": AppTheme.ACCENT, "label": Fmt.country(cid)},
	]
	_chart.set_series(series)

class_name CountryPanel
extends VBoxContainer
## Bảng bên phải: hồ sơ quốc gia đang chọn + bảng giá nhanh để mua/bán.

var main: MainUI
var country_id: String = ""
var _rows: Dictionary = {}   # commodity -> {price: Label, change: Label, sell: Button, buy: Button}
var _presence: VBoxContainer


func _init() -> void:
	add_theme_constant_override("separation", 10)


func set_country(id: String) -> void:
	country_id = id
	_rows.clear()
	UI.clear(self)
	var content: ContentRegistry = main.session.content
	var c: CountryDef = content.country(id)
	var head := UI.hbox(10)
	head.add_child(UI.color_dot(c.color, 18))
	var names := UI.vbox(0)
	names.add_child(UI.label(Fmt.country(id), "HeaderLabel"))
	names.add_child(UI.label("%s · %s · %s" % [Loc.t("REGION_" + c.region.to_upper()), c.currency, c.port_name], "MutedLabel"))
	head.add_child(names)
	add_child(head)
	var g := UI.grid(2, 18, 2)
	g.add_child(UI.stat(Loc.t("CP_POPULATION"), "%.1f %s" % [c.population / 1_000_000.0, Loc.t("UNIT_MILLION")]))
	g.add_child(UI.stat(Loc.t("CP_GDP_PC"), "$" + Money.group_thousands(int(c.gdp_per_capita))))
	add_child(g)
	# Tài nguyên chính
	var res: Array = c.resources.keys()
	res.sort_custom(func(a: String, b: String) -> bool:
		return float(c.resources[a]) * content.commodity(a).base_price > float(c.resources[b]) * content.commodity(b).base_price)
	var res_text: PackedStringArray = []
	for i in mini(4, res.size()):
		res_text.append(Fmt.commodity(res[i]))
	add_child(UI.label(Loc.t("CP_RESOURCES"), "SubHeaderLabel"))
	var rl := UI.wrap_label(", ".join(res_text), 360, "")
	add_child(rl)
	add_child(UI.label(Loc.t("CP_PRESENCE"), "SubHeaderLabel"))
	_presence = UI.vbox(6)
	add_child(_presence)
	add_child(UI.label(Loc.t("CP_MARKET"), "SubHeaderLabel"))
	add_child(UI.label(Loc.t("CP_MARKET_HINT"), "MutedLabel"))
	var table := UI.grid(5, 6, 3)
	for h: String in ["COL_COMMODITY", "COL_PRICE", "COL_MONTH", "", ""]:
		table.add_child(UI.label(Loc.t(h) if not h.is_empty() else "", "MutedLabel"))
	for kid in content.commodity_ids:
		var name_box := UI.hbox(6)
		name_box.add_child(UI.color_dot(content.commodity(kid).color, 8))
		name_box.add_child(UI.label(Fmt.commodity(kid)))
		name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		table.add_child(name_box)
		var price := UI.right(UI.label("-"))
		price.custom_minimum_size = Vector2(60, 0)
		table.add_child(price)
		var change := UI.right(UI.label("-", "", AppTheme.MUTED, 12))
		change.custom_minimum_size = Vector2(46, 0)
		table.add_child(change)
		var buy := UI.small_button(Loc.t("BTN_BUY"), main.open_trade.bind(true, id, kid))
		var sell := UI.small_button(Loc.t("BTN_SELL"), main.open_trade.bind(false, id, kid))
		table.add_child(buy)
		table.add_child(sell)
		_rows[kid] = {"price": price, "change": change, "buy": buy, "sell": sell}
	add_child(table)
	refresh()


func refresh() -> void:
	if country_id.is_empty() or _presence == null:
		return
	var w: WorldState = main.session.world()
	var co: String = main.session.company_id()
	var wh: String = InventoryQueries.warehouse_in(w, co, country_id)
	UI.clear(_presence)
	if wh.is_empty():
		_presence.add_child(UI.wrap_label(Loc.t("CP_NO_WAREHOUSE"), 360))
		var cost: int = Money.from_float(main.session.content.setting_f("warehouse.open_cost", 150000.0))
		_presence.add_child(UI.button(Loc.t("BTN_OPEN_WAREHOUSE", {"cost": Fmt.money(cost, true)}), main.open_warehouse.bind(country_id), "AccentButton"))
	else:
		var used: int = InventoryQueries.used(w, wh)
		var cap: int = int(InventoryQueries.warehouse(w, wh)["capacity"])
		var row := UI.hbox(8)
		row.add_child(UI.label(Loc.t("CP_WAREHOUSE_USAGE", {"used": Fmt.qty(used), "cap": Fmt.qty(cap)})))
		row.add_child(UI.progress(float(used), float(cap), AppTheme.INFO, 90))
		_presence.add_child(row)
		var facs: Array[Dictionary] = ProductionQueries.factories_in(w, co, country_id)
		for f in facs:
			_presence.add_child(UI.label("▪ %s — %s" % [Fmt.facility(str(f["facility"])), Loc.t("STATUS_" + str(f["status"]).to_upper())], "", AppTheme.GOOD))
		var btns := UI.hbox(6)
		btns.add_child(UI.button(Loc.t("BTN_BUILD_FACTORY"), main.open_build.bind(wh)))
		btns.add_child(UI.button(Loc.t("BTN_VIEW_WAREHOUSE"), main.show_screen.bind("warehouses")))
		_presence.add_child(btns)
	for kid: String in _rows:
		var r: Dictionary = _rows[kid]
		var p: float = MarketQueries.price(w, country_id, kid)
		var ratio: float = p / maxf(MarketQueries.world_price(w, kid), 0.01)
		var pl: Label = r["price"]
		pl.text = Fmt.price(p)
		pl.add_theme_color_override("font_color", AppTheme.GOOD if ratio < 0.95 else (AppTheme.BAD if ratio > 1.05 else AppTheme.TEXT))
		pl.tooltip_text = Loc.t("TIP_VS_WORLD", {"pct": Fmt.pct(ratio - 1.0), "world": Fmt.price(MarketQueries.world_price(w, kid))})
		pl.mouse_filter = Control.MOUSE_FILTER_PASS
		var ch: float = MarketQueries.month_change(w, country_id, kid)
		var cl: Label = r["change"]
		cl.text = Fmt.pct(ch)
		cl.add_theme_color_override("font_color", Fmt.signed_color(ch))
		(r["buy"] as Button).disabled = wh.is_empty()
		(r["sell"] as Button).disabled = wh.is_empty() or InventoryQueries.available(w, wh, kid) <= 0

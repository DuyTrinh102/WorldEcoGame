extends ScreenBase
## Nhà máy: trạng thái, sản lượng, nguyên liệu, hiệu quả; bật/tạm dừng; xây mới.

var _list: VBoxContainer


func setup() -> void:
	var root := UI.vbox(12)
	add_child(root)
	root.add_child(header("FAC_TITLE", "FAC_SUBTITLE"))
	_list = UI.vbox(12)
	root.add_child(UI.scroll(_list))


func refresh() -> void:
	var w: WorldState = world()
	var co: String = company()
	UI.clear(_list)
	var factories: Array[Dictionary] = ProductionQueries.factories_of(w, co)
	if factories.is_empty():
		var l := UI.label(Loc.t("FAC_EMPTY"), "MutedLabel")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(l)
	for f in factories:
		_list.add_child(_factory_card(w, f))
	_list.add_child(UI.label(Loc.t("FAC_RECIPES"), "SubHeaderLabel"))
	_list.add_child(_recipes_table(w))


func _factory_card(w: WorldState, f: Dictionary) -> PanelContainer:
	var def: FacilityDef = content().facility(str(f["facility"]))
	var card := UI.card()
	var v := UI.vbox(8)
	card.add_child(v)
	var head := UI.hbox(12)
	head.add_child(UI.bold(Fmt.facility(def.id), AppTheme.TEXT, 16))
	head.add_child(UI.label("· " + Fmt.country(str(f["country"])), "MutedLabel"))
	var status: String = str(f["status"])
	var status_color: Color = {"running": AppTheme.GOOD, "building": AppTheme.INFO, "no_input": AppTheme.BAD, "paused": AppTheme.WARN}.get(status, AppTheme.TEXT)
	head.add_child(UI.bold(Loc.t("STATUS_" + status.to_upper()), status_color, 14))
	head.add_child(UI.spacer())
	if status != ProductionQueries.STATUS_BUILDING:
		var active: bool = bool(f["active"])
		head.add_child(UI.button(Loc.t("BTN_PAUSE") if active else Loc.t("BTN_RESUME"), func() -> void:
			main.submit(SetFactoryActiveCommand.create(company(), str(f["id"]), not active))))
	v.add_child(head)
	if status == ProductionQueries.STATUS_BUILDING:
		var total: float = float(def.build_days)
		var left: int = int(f["complete_day"]) - w.day
		var row := UI.hbox(10)
		row.add_child(UI.label(Loc.t("FAC_BUILDING", {"days": left, "date": Fmt.date(int(f["complete_day"]))})))
		row.add_child(UI.progress(total - float(left), total, AppTheme.INFO, 200))
		v.add_child(row)
		return card
	var stats := UI.hbox(30)
	stats.add_child(UI.stat(Loc.t("FAC_CAPACITY"), Fmt.qty(def.capacity_per_day) + Loc.t("UNIT_PER_DAY")))
	stats.add_child(UI.stat(Loc.t("FAC_MONTH_OUTPUT"), Fmt.qty(int(f["month_output"]))))
	stats.add_child(UI.stat(Loc.t("FAC_LAST_MONTH"), Fmt.qty(int(f["last_month_output"]))))
	stats.add_child(UI.stat(Loc.t("FAC_TOTAL"), Fmt.qty(int(f["total_output"]))))
	var econ: Dictionary = ProductionQueries.unit_economics(w, content(), def.id, str(f["country"]))
	var margin: float = float(econ["margin"])
	stats.add_child(UI.stat(Loc.t("DLG_ECON_MARGIN"), (Fmt.price(margin) if margin >= 0 else "-" + Fmt.price(-margin)) + "/t", Fmt.signed_color(margin)))
	v.add_child(stats)
	var wh: String = str(f["warehouse"])
	var inputs := UI.hbox(18)
	inputs.add_child(UI.label(Loc.t("FAC_INPUTS"), "MutedLabel"))
	for k: String in def.inputs:
		var need_per_day: float = float(def.inputs[k]) * Quantity.to_float(def.capacity_per_day)
		var have: float = Quantity.to_float(InventoryQueries.available(w, wh, k))
		var days: int = int(have / maxf(need_per_day, 0.001))
		var box := UI.hbox(6)
		box.add_child(UI.color_dot(content().commodity(k).color, 8))
		box.add_child(UI.label(Loc.t("FAC_INPUT_VALUE", {"commodity": Fmt.commodity(k), "qty": Fmt.qty(Quantity.from_float(have)), "days": days}), "", AppTheme.BAD if days < 3 else AppTheme.TEXT))
		box.add_child(UI.button(Loc.t("BTN_BUY"), main.open_trade.bind(true, str(f["country"]), k)))
		inputs.add_child(box)
	v.add_child(inputs)
	var out_q: int = InventoryQueries.available(w, wh, def.output)
	var out_row := UI.hbox(10)
	out_row.add_child(UI.label(Loc.t("FAC_OUTPUT_STOCK", {"commodity": Fmt.commodity(def.output), "qty": Fmt.qty(out_q)})))
	if out_q > 0:
		out_row.add_child(UI.button(Loc.t("BTN_SELL"), main.open_trade.bind(false, str(f["country"]), def.output)))
		out_row.add_child(UI.button(Loc.t("BTN_SHIP"), main.open_ship.bind(wh, def.output)))
	v.add_child(out_row)
	return card


func _recipes_table(w: WorldState) -> PanelContainer:
	var card := UI.card()
	var g := UI.grid(content().country_ids.size() + 1, 12, 4)
	g.add_child(UI.label(Loc.t("FAC_RECIPE_MARGIN"), "MutedLabel"))
	for cid in content().country_ids:
		var h := UI.label(Fmt.country(cid), "MutedLabel")
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.custom_minimum_size = Vector2(76, 0)
		g.add_child(h)
	for fid in content().facility_ids:
		g.add_child(UI.label(Fmt.facility(fid)))
		for cid in content().country_ids:
			var m: float = float(ProductionQueries.unit_economics(w, content(), fid, cid)["margin"])
			g.add_child(UI.right(UI.label((Fmt.price(m) if m >= 0 else "-" + Fmt.price(-m)), "", Fmt.signed_color(m))))
	card.add_child(g)
	return card

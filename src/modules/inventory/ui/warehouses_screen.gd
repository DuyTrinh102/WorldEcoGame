extends ScreenBase
## Kho bãi: tồn kho theo kho, giá vốn, giá trị thị trường, bán/vận chuyển, mở kho mới.

var _list: VBoxContainer
var _country_pick: OptionButton


func setup() -> void:
	var root := UI.vbox(12)
	add_child(root)
	var top := UI.hbox(10)
	top.add_child(header("WH_TITLE", "WH_SUBTITLE"))
	top.add_child(UI.spacer())
	_country_pick = OptionButton.new()
	_country_pick.focus_mode = Control.FOCUS_NONE
	top.add_child(_country_pick)
	top.add_child(UI.button(Loc.t("BTN_OPEN_WAREHOUSE_SHORT"), _open_selected, "AccentButton"))
	root.add_child(top)
	_list = UI.vbox(12)
	root.add_child(UI.scroll(_list))


func _open_selected() -> void:
	if _country_pick.item_count == 0 or _country_pick.selected < 0:
		return
	main.open_warehouse(str(_country_pick.get_item_metadata(_country_pick.selected)))


func refresh() -> void:
	var w: WorldState = world()
	var co: String = company()
	var prev: String = str(_country_pick.get_item_metadata(_country_pick.selected)) if _country_pick.selected >= 0 else ""
	_country_pick.clear()
	for cid in content().country_ids:
		if InventoryQueries.warehouse_in(w, co, cid).is_empty():
			_country_pick.add_item(Fmt.country(cid))
			_country_pick.set_item_metadata(_country_pick.item_count - 1, cid)
			if cid == prev:
				_country_pick.select(_country_pick.item_count - 1)
	UI.clear(_list)
	for wh in InventoryQueries.warehouses_of(w, co):
		_list.add_child(_warehouse_card(w, co, wh))


func _warehouse_card(w: WorldState, co: String, wh: String) -> PanelContainer:
	var info: Dictionary = InventoryQueries.warehouse(w, wh)
	var cid: String = str(info["country"])
	var card := UI.card()
	var v := UI.vbox(8)
	card.add_child(v)
	var head := UI.hbox(12)
	head.add_child(UI.color_dot(content().country(cid).color, 14))
	head.add_child(UI.bold(Loc.t("WH_CARD_TITLE", {"country": Fmt.country(cid)}), AppTheme.TEXT, 16))
	var used: int = InventoryQueries.used(w, wh)
	var cap: int = int(info["capacity"])
	head.add_child(UI.label(Loc.t("CP_WAREHOUSE_USAGE", {"used": Fmt.qty(used), "cap": Fmt.qty(cap)}), "MutedLabel"))
	head.add_child(UI.progress(float(used), float(cap), AppTheme.INFO, 140))
	head.add_child(UI.spacer())
	head.add_child(UI.button(Loc.t("BTN_BUILD_FACTORY"), main.open_build.bind(wh)))
	head.add_child(UI.button(Loc.t("BTN_GO_MARKET"), func() -> void:
		main.select_country(cid)
		main.show_screen("map")))
	v.add_child(head)
	for f in ProductionQueries.factories_in(w, co, cid):
		v.add_child(UI.label("▪ %s — %s" % [Fmt.facility(str(f["facility"])), Loc.t("STATUS_" + str(f["status"]).to_upper())], "", AppTheme.GOOD))
	var items: Array[String] = InventoryQueries.items(w, wh)
	if items.is_empty():
		v.add_child(UI.label(Loc.t("WH_EMPTY"), "MutedLabel"))
		return card
	var g := UI.grid(8, 16, 4)
	for h: String in ["COL_COMMODITY", "COL_QTY", "COL_AVG_COST", "COL_PRICE_HERE", "COL_MARKET_VALUE", "COL_UNREALIZED", "", ""]:
		g.add_child(UI.label(Loc.t(h) if not h.is_empty() else "", "MutedLabel"))
	for kid in items:
		var q: int = InventoryQueries.available(w, wh, kid)
		var cost: int = InventoryQueries.cost_of(w, wh, kid)
		var price: float = MarketQueries.price(w, cid, kid)
		var value: int = UnitPrice.total(UnitPrice.from_float(price), q)
		var name_box := UI.hbox(6)
		name_box.add_child(UI.color_dot(content().commodity(kid).color, 8))
		name_box.add_child(UI.label(Fmt.commodity(kid)))
		name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(name_box)
		g.add_child(UI.right(UI.label(Fmt.qty(q))))
		g.add_child(UI.right(UI.label(Fmt.unit_price(InventoryQueries.avg_cost(w, wh, kid)))))
		g.add_child(UI.right(UI.label(Fmt.price(price))))
		g.add_child(UI.right(UI.label(Fmt.money(value, true))))
		g.add_child(UI.right(UI.label(Fmt.money(value - cost, true), "", Fmt.signed_color(float(value - cost)))))
		g.add_child(UI.button(Loc.t("BTN_SELL"), main.open_trade.bind(false, cid, kid)))
		g.add_child(UI.button(Loc.t("BTN_SHIP"), main.open_ship.bind(wh, kid)))
	v.add_child(g)
	return card

class_name ShipDialog
extends FormDialog
## Tạo chuyến hàng giữa hai kho: chọn kho đích, số lượng; xem trước quãng đường, thời gian, cước.

var from_wh: String = ""
var commodity_id: String = ""
var _dest: OptionButton
var qty_box: SpinBox
var _route: Label = UI.label("")
var _eta: Label = UI.label("")
var _freight: Label = UI.label("")
var _landed: Label = UI.label("")
var _margin: Label = UI.label("")


static func create(p_main: MainUI, warehouse: String, commodity: String) -> ShipDialog:
	var d := ShipDialog.new()
	d.from_wh = warehouse
	d.commodity_id = commodity
	d.init_dialog(p_main, Loc.t("DLG_SHIP_TITLE", {"commodity": Fmt.commodity(commodity)}), Loc.t("BTN_SHIP"))
	d._build()
	return d


func _build() -> void:
	var w: WorldState = main.session.world()
	var co: String = main.session.company_id()
	var from_country: String = str(InventoryQueries.warehouse(w, from_wh)["country"])
	body.add_child(UI.label(Loc.t("DLG_SHIP_FROM", {"country": Fmt.country(from_country), "qty": Fmt.qty(InventoryQueries.available(w, from_wh, commodity_id))})))
	var row := UI.hbox(8)
	row.add_child(UI.label(Loc.t("DLG_SHIP_TO")))
	_dest = OptionButton.new()
	_dest.focus_mode = Control.FOCUS_NONE
	for wh in InventoryQueries.warehouses_of(w, co):
		if wh == from_wh:
			continue
		_dest.add_item(Fmt.country(str(InventoryQueries.warehouse(w, wh)["country"])))
		_dest.set_item_metadata(_dest.item_count - 1, wh)
	_dest.item_selected.connect(func(_i: int) -> void: update_preview())
	row.add_child(_dest)
	body.add_child(row)
	if _dest.item_count == 0:
		body.add_child(UI.wrap_label(Loc.t("DLG_SHIP_NEED_WAREHOUSE"), 440, "", AppTheme.WARN))
		get_ok_button().disabled = true
	var qrow := UI.hbox(6)
	qrow.add_child(UI.label(Loc.t("DLG_QUANTITY")))
	var have_t: float = Quantity.to_float(InventoryQueries.available(w, from_wh, commodity_id))
	qty_box = FormDialog.qty_input(have_t, have_t, update_preview)
	qrow.add_child(qty_box)
	qrow.add_child(UI.button(Loc.t("BTN_MAX"), func() -> void: qty_box.value = qty_box.max_value))
	body.add_child(qrow)
	var g := UI.grid(2, 24, 4)
	FormDialog.info_row(g, "DLG_ROUTE", _route)
	FormDialog.info_row(g, "DLG_ETA", _eta)
	FormDialog.info_row(g, "DLG_FREIGHT", _freight)
	FormDialog.info_row(g, "DLG_LANDED_COST", _landed)
	FormDialog.info_row(g, "DLG_DEST_MARGIN", _margin)
	body.add_child(g)
	body.add_child(UI.wrap_label(Loc.t("DLG_SHIP_NOTE"), 440))
	finish_layout()


func _dest_wh() -> String:
	if _dest == null or _dest.item_count == 0 or _dest.selected < 0:
		return ""
	return str(_dest.get_item_metadata(_dest.selected))


func update_preview() -> void:
	var to: String = _dest_wh()
	if to.is_empty() or qty_box == null:
		return
	var w: WorldState = main.session.world()
	var content: ContentRegistry = main.session.content
	var a: String = str(InventoryQueries.warehouse(w, from_wh)["country"])
	var b: String = str(InventoryQueries.warehouse(w, to)["country"])
	var q: int = Quantity.from_float(qty_box.value)
	var quote: Dictionary = LogisticsQueries.quote(content, a, b, q)
	_route.text = Loc.t("DLG_ROUTE_VALUE", {"km": Money.group_thousands(int(quote["distance_km"])), "days": quote["days"]})
	_eta.text = Fmt.date(w.day + int(quote["days"]))
	_freight.text = "%s (%s/t)" % [Fmt.money(int(quote["freight"]), true), Fmt.unit_price(int(quote["freight_per_unit"]))]
	var landed: float = UnitPrice.to_float(InventoryQueries.avg_cost(w, from_wh, commodity_id)) + UnitPrice.to_float(int(quote["freight_per_unit"]))
	_landed.text = Fmt.price(landed) + "/t"
	var dest_price: float = MarketQueries.price(w, b, commodity_id)
	var margin: float = dest_price - landed
	_margin.text = "%s/t (%s %s)" % [Fmt.price(margin) if margin >= 0 else "-" + Fmt.price(-margin), Loc.t("DLG_AT_PRICE"), Fmt.price(dest_price)]
	_margin.add_theme_color_override("font_color", Fmt.signed_color(margin))


func build_command() -> SimCommand:
	var to: String = _dest_wh()
	if to.is_empty():
		return null
	return ShipCommand.create(main.session.company_id(), from_wh, to, commodity_id, Quantity.from_float(qty_box.value))


func on_success(r: Result) -> void:
	main.toast(Loc.t("TOAST_SHIPPED", {"days": r.value["days"]}), AppTheme.GOOD)

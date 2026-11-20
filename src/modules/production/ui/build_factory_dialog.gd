class_name BuildFactoryDialog
extends FormDialog
## Xây nhà máy tại một kho: chọn loại cơ sở, xem công thức và hiệu quả kinh tế ước tính.

var warehouse_id: String = ""
var _type: OptionButton
var _details: VBoxContainer


static func create(p_main: MainUI, warehouse: String) -> BuildFactoryDialog:
	var d := BuildFactoryDialog.new()
	d.warehouse_id = warehouse
	var country: String = str(InventoryQueries.warehouse(p_main.session.world(), warehouse)["country"])
	d.init_dialog(p_main, Loc.t("DLG_BUILD_TITLE", {"country": Fmt.country(country)}), Loc.t("BTN_BUILD"))
	d._build()
	return d


func _build() -> void:
	body.custom_minimum_size = Vector2(540, 0)
	var row := UI.hbox(8)
	row.add_child(UI.label(Loc.t("DLG_FACILITY_TYPE")))
	_type = OptionButton.new()
	_type.focus_mode = Control.FOCUS_NONE
	for fid in main.session.content.facility_ids:
		_type.add_item(Fmt.facility(fid))
		_type.set_item_metadata(_type.item_count - 1, fid)
	_type.item_selected.connect(func(_i: int) -> void: update_preview())
	row.add_child(_type)
	body.add_child(row)
	_details = UI.vbox(6)
	body.add_child(_details)
	finish_layout()


func _facility() -> String:
	return str(_type.get_item_metadata(maxi(0, _type.selected)))


func update_preview() -> void:
	if _details == null:
		return
	UI.clear(_details)
	var w: WorldState = main.session.world()
	var content: ContentRegistry = main.session.content
	var fid: String = _facility()
	var f: FacilityDef = content.facility(fid)
	var country: String = str(InventoryQueries.warehouse(w, warehouse_id)["country"])
	_details.add_child(UI.wrap_label(Loc.t(f.description_key), 520))
	var g := UI.grid(2, 24, 4)
	FormDialog.info_row(g, "DLG_BUILD_COST", UI.bold(Fmt.money(f.build_cost, true)))
	FormDialog.info_row(g, "DLG_BUILD_TIME", UI.label(Loc.t("UNIT_DAYS", {"n": f.build_days})))
	FormDialog.info_row(g, "DLG_CAPACITY", UI.label(Loc.t("DLG_CAPACITY_VALUE", {"day": Fmt.qty(f.capacity_per_day), "month": Fmt.qty(f.capacity_per_day * 30), "commodity": Fmt.commodity(f.output)})))
	var inputs: PackedStringArray = []
	for k: String in f.inputs:
		inputs.append("%.2f t %s" % [float(f.inputs[k]), Fmt.commodity(k)])
	FormDialog.info_row(g, "DLG_RECIPE", UI.label(" + ".join(inputs) + "  →  1 t " + Fmt.commodity(f.output)))
	FormDialog.info_row(g, "DLG_VAR_COST", UI.label(Fmt.unit_price(f.variable_cost_per_unit) + "/t"))
	FormDialog.info_row(g, "DLG_OVERHEAD", UI.label(Fmt.money(f.monthly_overhead, true) + Loc.t("UNIT_PER_MONTH")))
	FormDialog.info_row(g, "DLG_DEPRECIATION", UI.label(Loc.t("DLG_DEPRECIATION_VALUE", {"years": f.depreciation_years})))
	_details.add_child(g)
	_details.add_child(UI.sep())
	var econ: Dictionary = ProductionQueries.unit_economics(w, content, fid, country)
	_details.add_child(UI.label(Loc.t("DLG_ECON_TITLE", {"country": Fmt.country(country)}), "SubHeaderLabel"))
	var e := UI.grid(2, 24, 4)
	FormDialog.info_row(e, "DLG_ECON_INPUT", UI.label(Fmt.price(float(econ["input_cost"])) + "/t"))
	FormDialog.info_row(e, "DLG_ECON_OUTPUT", UI.label(Fmt.price(float(econ["output_price"])) + "/t"))
	var margin: float = float(econ["margin"])
	FormDialog.info_row(e, "DLG_ECON_MARGIN", UI.label((Fmt.price(margin) if margin >= 0 else "-" + Fmt.price(-margin)) + "/t", "", Fmt.signed_color(margin)))
	var monthly: float = margin * Quantity.to_float(f.capacity_per_day) * 30.0 - Money.to_float(f.monthly_overhead)
	FormDialog.info_row(e, "DLG_ECON_MONTHLY", UI.bold(Fmt.money(Money.from_float(monthly), true), Fmt.signed_color(monthly)))
	_details.add_child(e)
	_details.add_child(UI.wrap_label(Loc.t("DLG_ECON_HINT"), 520))
	fit_to_content.call_deferred()


func build_command() -> SimCommand:
	return BuildFactoryCommand.create(main.session.company_id(), warehouse_id, _facility())


func on_success(_r: Result) -> void:
	main.toast(Loc.t("TOAST_FACTORY_STARTED", {"facility": Fmt.facility(_facility())}), AppTheme.GOOD)

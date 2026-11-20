class_name TopBar
extends PanelContainer
## Thanh trạng thái: công ty, chỉ số tài chính chính, mục tiêu, ngày, tốc độ, lưu/tải.

var main: MainUI
var _stats: Dictionary = {}
var _date: Label
var _company: Label
var _goal_bar: ProgressBar
var _goal_label: Label
var _speed_buttons: Array[Button] = []


func setup() -> void:
	theme_type_variation = "BarPanel"
	var h := UI.hbox(14)
	add_child(h)
	var brand := UI.vbox(0)
	brand.add_child(UI.bold("WORLD ECONOMY", AppTheme.ACCENT, 16))
	_company = UI.label("", "MutedLabel")
	brand.add_child(_company)
	h.add_child(brand)
	for key: String in ["cash", "inventory", "receivables", "debt", "net_worth"]:
		var s := UI.stat(Loc.t("TOP_" + key.to_upper()), "-")
		h.add_child(s)
		_stats[key] = s.get_node("Value")
	var goal := UI.vbox(2)
	_goal_label = UI.label("", "MutedLabel")
	goal.add_child(_goal_label)
	_goal_bar = UI.progress(0.0, 1.0, AppTheme.ACCENT, 120)
	goal.add_child(_goal_bar)
	h.add_child(goal)
	h.add_child(UI.spacer())
	var time_box := UI.vbox(2)
	_date = UI.bold("", AppTheme.TEXT, 17)
	_date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_box.add_child(_date)
	var speeds := UI.hbox(3)
	var labels: Array[String] = ["II", "1x", "2x", "5x", "10x"]
	var group := ButtonGroup.new()
	for i in labels.size():
		var b := UI.button(labels[i], main.session.set_speed.bind(i))
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size = Vector2(36, 0)
		b.tooltip_text = Loc.t("TIP_SPEED_%d" % i)
		speeds.add_child(b)
		_speed_buttons.append(b)
	time_box.add_child(speeds)
	h.add_child(time_box)
	var menu := UI.hbox(4)
	menu.add_child(UI.button(Loc.t("BTN_SAVE"), quick_save))
	menu.add_child(UI.button(Loc.t("BTN_LOAD"), quick_load))
	menu.add_child(UI.button(Loc.t("BTN_NEW_GAME_SHORT"), _confirm_new_game))
	menu.add_child(UI.button("?", main.show_welcome))
	h.add_child(menu)
	main.session.speed_changed.connect(_on_speed_changed)
	_on_speed_changed(main.session.speed_index)


func refresh() -> void:
	var w: WorldState = main.session.world()
	var c: ContentRegistry = main.session.content
	var co: String = main.session.company_id()
	_company.text = str(CorporateQueries.player(w).get("name", ""))
	var cash: int = FinanceQueries.cash(w, co)
	_set_stat("cash", Fmt.money(cash, true), AppTheme.BAD if cash < 0 else AppTheme.GOOD)
	var stock: int = FinanceQueries.balance(w, co, Accounts.INVENTORY) + FinanceQueries.balance(w, co, Accounts.INVENTORY_TRANSIT)
	_set_stat("inventory", Fmt.money(stock, true))
	_set_stat("receivables", Fmt.money(FinanceQueries.balance(w, co, Accounts.RECEIVABLES), true))
	var debt: int = FinanceQueries.debt(w, co)
	_set_stat("debt", Fmt.money(debt, true), AppTheme.WARN if debt > 0 else AppTheme.TEXT)
	var nw: int = FinanceQueries.net_worth(w, c, co)
	var start: int = Money.from_float(float(c.scenarios["default"].get("start_cash", 5_000_000)))
	_set_stat("net_worth", Fmt.money(nw, true), Fmt.signed_color(float(nw - start)))
	var goal: int = start * 2
	_goal_label.text = Loc.t("TOP_GOAL", {"goal": Fmt.money(goal, true)})
	_goal_bar.value = clampf(float(nw) / float(goal), 0.0, 1.0)
	_date.text = Fmt.date(w.day)


func _set_stat(key: String, text: String, color: Color = AppTheme.TEXT) -> void:
	var l: Label = _stats[key]
	l.text = text
	l.add_theme_color_override("font_color", color)


func _on_speed_changed(index: int) -> void:
	for i in _speed_buttons.size():
		_speed_buttons[i].set_pressed_no_signal(i == index)


func quick_save() -> void:
	var r: Result = main.session.save_game()
	main.toast(Loc.t("TOAST_SAVED") if r.ok else Fmt.error_text(r), AppTheme.GOOD if r.ok else AppTheme.BAD)


func quick_load() -> void:
	if not main.session.has_save():
		main.toast(Loc.t("ERR_SAVE_NOT_FOUND"), AppTheme.BAD)
		return
	var r: Result = main.session.load_game()
	main.toast(Loc.t("TOAST_LOADED") if r.ok else Fmt.error_text(r), AppTheme.GOOD if r.ok else AppTheme.BAD)


func _confirm_new_game() -> void:
	var d := ConfirmationDialog.new()
	d.title = Loc.t("BTN_NEW_GAME")
	d.dialog_text = Loc.t("DLG_NEW_GAME_TEXT")
	d.ok_button_text = Loc.t("BTN_CONFIRM")
	d.cancel_button_text = Loc.t("BTN_CANCEL")
	d.confirmed.connect(func() -> void: main.session.new_game())
	d.visibility_changed.connect(func() -> void:
		if not d.visible:
			d.queue_free())
	main.open_dialog(d)

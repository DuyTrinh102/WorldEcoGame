class_name MainUI
extends Control
## Màn hình chính: thanh trạng thái (trên), điều hướng module (trái), bản đồ/màn hình (giữa),
## thông tin quốc gia đang chọn (phải), dải tin tức (dưới). Dựng hoàn toàn bằng code.

const REFRESH_INTERVAL: float = 0.2
const NEWS_SCREEN_PATH: String = "res://src/ui/hud/news_screen.gd"

var session: Node
var bridge: Node
var map: WorldMap
var top_bar: TopBar
var country_panel: CountryPanel
var selected_country: String = ""
var current_screen: String = "map"

var _center: Control
var _screens: Dictionary = {}      # id -> Control
var _nav_buttons: Dictionary = {}  # id -> Button
var _ticker: HBoxContainer
var _toast: PanelContainer
var _toast_label: Label
var _toast_time: float = 0.0
var _dirty: bool = true
var _since_refresh: float = 0.0


func _ready() -> void:
	session = get_node("/root/GameSession")
	bridge = get_node("/root/SimBridge")
	theme = AppTheme.build()
	get_window().min_size = Vector2i(1280, 720)
	var bg := ColorRect.new()
	bg.color = AppTheme.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	if not session.is_ready():
		_show_content_errors()
		return
	_build()
	session.state_changed.connect(func() -> void: _dirty = true)
	session.game_started.connect(_on_game_started)
	bridge.events_published.connect(_on_events)
	_on_game_started()
	show_screen("map")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			var dev: Node = (load("res://src/app/dev_capture.gd") as Script).new()
			dev.set("main", self)
			add_child(dev)
	if not "--no-welcome" in OS.get_cmdline_user_args():
		call_deferred("show_welcome")


func _build() -> void:
	var root := UI.vbox(0)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	top_bar = TopBar.new()
	top_bar.main = self
	root.add_child(top_bar)
	top_bar.setup()
	var body := UI.hbox(0)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	# Điều hướng trái
	var nav_panel := UI.card("BarPanel")
	nav_panel.custom_minimum_size = Vector2(176, 0)
	body.add_child(nav_panel)
	var nav := UI.vbox(4)
	nav_panel.add_child(nav)
	nav.add_child(UI.label(Loc.t("NAV_SECTION"), "MutedLabel"))
	var group := ButtonGroup.new()
	var entries: Array[Dictionary] = [{"id": "map", "title_key": "NAV_MAP", "path": ""}]
	entries.append_array(session.sim.ui_screens)
	entries.append({"id": "news", "title_key": "NAV_NEWS", "path": NEWS_SCREEN_PATH})
	_center = Control.new()
	_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_center.clip_contents = true
	for e in entries:
		var id: String = str(e["id"])
		var b := UI.button(Loc.t(str(e["title_key"])), show_screen.bind(id), "NavButton")
		b.toggle_mode = true
		b.button_group = group
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		nav.add_child(b)
		_nav_buttons[id] = b
		var screen: Control
		if id == "map":
			map = WorldMap.new()
			map.setup(self)
			map.country_selected.connect(select_country)
			screen = map
		else:
			screen = (load(str(e["path"])) as Script).new()
			(screen as ScreenBase).main = self
			(screen as ScreenBase).setup()
		screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		screen.visible = false
		_center.add_child(screen)
		_screens[id] = screen
	nav.add_child(UI.spacer(false))
	nav.add_child(UI.label(Loc.t("NAV_SHORTCUTS"), "MutedLabel"))
	body.add_child(_center)
	# Bảng phải
	var right := UI.card("BarPanel")
	right.custom_minimum_size = Vector2(420, 0)
	body.add_child(right)
	country_panel = CountryPanel.new()
	country_panel.main = self
	right.add_child(UI.scroll(country_panel))
	# Dải tin dưới
	var bottom := UI.card("BarPanel")
	bottom.custom_minimum_size = Vector2(0, 34)
	bottom.clip_contents = true
	root.add_child(bottom)
	_ticker = UI.hbox(18)
	bottom.add_child(_ticker)
	_ticker.add_child(UI.bold(Loc.t("TICKER_TITLE"), AppTheme.ACCENT, 13))
	# Toast thông báo
	_toast = UI.card("CardPanel")
	_toast.visible = false
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_label = UI.label("")
	_toast.add_child(_toast_label)
	add_child(_toast)


func _on_game_started() -> void:
	var home: String = str(CorporateQueries.player(session.world()).get("home_country", session.content.country_ids[0]))
	select_country(home)
	_rebuild_ticker()
	_dirty = true


func select_country(id: String) -> void:
	selected_country = id
	if map != null:
		map.selected = id
		map.queue_redraw()
	country_panel.set_country(id)


func show_screen(id: String) -> void:
	if not _screens.has(id):
		return
	current_screen = id
	for k: String in _screens:
		(_screens[k] as Control).visible = k == id
	for k: String in _nav_buttons:
		(_nav_buttons[k] as Button).set_pressed_no_signal(k == id)
	_refresh_current()


func _refresh_current() -> void:
	var s: Control = _screens.get(current_screen)
	if s is ScreenBase:
		(s as ScreenBase).refresh()
	elif s is WorldMap:
		(s as WorldMap).refresh()


func _process(delta: float) -> void:
	if _toast != null and _toast.visible:
		_toast_time -= delta
		_toast.modulate.a = clampf(_toast_time / 0.4, 0.0, 1.0)
		if _toast_time <= 0.0:
			_toast.visible = false
	if session == null or not session.is_ready() or top_bar == null:
		return
	_since_refresh += delta
	if _dirty and _since_refresh >= REFRESH_INTERVAL:
		_dirty = false
		_since_refresh = 0.0
		top_bar.refresh()
		country_panel.refresh()
		_refresh_current()


func _on_events(events: Array) -> void:
	for e: SimEvent in events:
		if e.importance >= SimEvent.Importance.HIGH and e.company_id == session.company_id():
			toast(Fmt.event_text(e), AppTheme.WARN)
	_rebuild_ticker()


func _rebuild_ticker() -> void:
	while _ticker.get_child_count() > 1:
		var c: Node = _ticker.get_child(1)
		_ticker.remove_child(c)
		c.queue_free()
	var shown: int = 0
	var entries: Array = bridge.log_entries
	for i in range(entries.size() - 1, -1, -1):
		var e: SimEvent = entries[i]
		if e.importance < SimEvent.Importance.NORMAL:
			continue
		var color: Color = AppTheme.WARN if e.importance >= SimEvent.Importance.HIGH else AppTheme.TEXT
		var item := UI.label("%s  %s" % [Fmt.date(e.day), Fmt.event_text(e)], "", color, 13)
		# Cắt chữ dài để dải tin không đẩy rộng toàn bộ giao diện.
		item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.size_flags_stretch_ratio = 1.0 if shown > 0 else 1.6
		item.custom_minimum_size = Vector2(60, 0)
		item.tooltip_text = item.text
		item.mouse_filter = Control.MOUSE_FILTER_PASS
		_ticker.add_child(item)
		shown += 1
		if shown >= 3:
			break
	if shown == 0:
		_ticker.add_child(UI.label(Loc.t("TICKER_EMPTY"), "MutedLabel"))


## Thông báo nổi ở giữa phía trên.
func toast(text: String, color: Color = AppTheme.TEXT) -> void:
	_toast_label.text = text
	_toast_label.add_theme_color_override("font_color", color)
	_toast.visible = true
	_toast.modulate.a = 1.0
	_toast_time = 3.5
	_toast.reset_size()
	_toast.position = Vector2((size.x - _toast.size.x) / 2.0, 70)


## Gửi command; báo lỗi bằng toast nếu thất bại.
func submit(cmd: SimCommand) -> Result:
	var r: Result = session.submit(cmd)
	if not r.ok:
		toast(Fmt.error_text(r), AppTheme.BAD)
	return r


func open_dialog(dialog: Window) -> void:
	add_child(dialog)
	dialog.popup_centered()


func open_trade(is_buy: bool, country_id: String, commodity_id: String) -> void:
	open_dialog(TradeDialog.create(self, is_buy, country_id, commodity_id))


func open_ship(from_wh: String, commodity_id: String) -> void:
	open_dialog(ShipDialog.create(self, from_wh, commodity_id))


func open_build(warehouse_id: String) -> void:
	open_dialog(BuildFactoryDialog.create(self, warehouse_id))


func open_warehouse(country_id: String) -> void:
	var cost: int = Money.from_float(session.content.setting_f("warehouse.open_cost", 150000.0))
	var d := ConfirmationDialog.new()
	d.title = Loc.t("DLG_OPEN_WH_TITLE")
	d.dialog_text = Loc.t("DLG_OPEN_WH_TEXT", {
		"country": Fmt.country(country_id),
		"cost": Fmt.money(cost, true),
		"rent": Fmt.money(Money.from_float(session.content.setting_f("warehouse.monthly_rent", 12000.0)), true),
		"capacity": Fmt.qty(Quantity.from_float(session.content.setting_f("warehouse.capacity_t", 30000.0))),
	})
	d.ok_button_text = Loc.t("BTN_CONFIRM")
	d.cancel_button_text = Loc.t("BTN_CANCEL")
	d.confirmed.connect(func() -> void:
		if submit(OpenWarehouseCommand.create(session.company_id(), country_id)).ok:
			toast(Loc.t("TOAST_WH_OPENED", {"country": Fmt.country(country_id)}), AppTheme.GOOD))
	d.visibility_changed.connect(func() -> void:
		if not d.visible:
			d.queue_free())
	open_dialog(d)


func show_welcome() -> void:
	var d := AcceptDialog.new()
	d.title = Loc.t("WELCOME_TITLE")
	d.ok_button_text = Loc.t("WELCOME_OK")
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.custom_minimum_size = Vector2(620, 0)
	text.text = Loc.t("WELCOME_TEXT")
	text.add_theme_color_override("default_color", AppTheme.TEXT)
	text.add_theme_font_override("bold_font", AppTheme.font(true))
	d.add_child(text)
	d.visibility_changed.connect(func() -> void:
		if not d.visible:
			d.queue_free())
	open_dialog(d)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not (event as InputEventKey).pressed or (event as InputEventKey).echo:
		return
	match (event as InputEventKey).keycode:
		KEY_SPACE:
			session.toggle_pause()
		KEY_1:
			session.set_speed(1)
		KEY_2:
			session.set_speed(2)
		KEY_3:
			session.set_speed(3)
		KEY_4:
			session.set_speed(4)
		KEY_F5:
			top_bar.quick_save()
		KEY_F9:
			top_bar.quick_load()
		_:
			return
	get_viewport().set_input_as_handled()


func _show_content_errors() -> void:
	var v := UI.vbox(6)
	v.position = Vector2(40, 40)
	v.add_child(UI.label("Lỗi dữ liệu game — không thể khởi động:", "HeaderLabel"))
	for e: String in session.content_errors:
		v.add_child(UI.label("• " + e, "", AppTheme.BAD))
	add_child(v)

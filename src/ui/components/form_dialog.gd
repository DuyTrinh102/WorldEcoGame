class_name FormDialog
extends ConfirmationDialog
## Hộp thoại biểu mẫu: nội dung + dòng báo lỗi; chỉ đóng khi xác nhận thành công.

var main: MainUI
var body: VBoxContainer
var error_label: Label


func init_dialog(p_main: MainUI, title_text: String, ok_text: String) -> void:
	main = p_main
	title = title_text
	ok_button_text = ok_text
	cancel_button_text = Loc.t("BTN_CANCEL")
	dialog_hide_on_ok = false
	exclusive = true
	body = UI.vbox(10)
	body.custom_minimum_size = Vector2(460, 0)
	add_child(body)
	error_label = UI.wrap_label("", 440, "", AppTheme.BAD)
	confirmed.connect(_try_confirm)
	canceled.connect(queue_free)
	close_requested.connect(queue_free)


## Gọi sau khi đã thêm nội dung vào body.
func finish_layout() -> void:
	body.add_child(error_label)
	update_preview()


func update_preview() -> void:
	pass


## Co lại kích thước theo nội dung và căn giữa (gọi khi nội dung thay đổi nhiều).
func fit_to_content() -> void:
	reset_size()
	if visible:
		move_to_center()


## Trả về command cần gửi (hoặc null).
func build_command() -> SimCommand:
	return null


func on_success(_result: Result) -> void:
	pass


func _try_confirm() -> void:
	var cmd: SimCommand = build_command()
	if cmd == null:
		return
	var r: Result = main.session.submit(cmd)
	if r.ok:
		on_success(r)
		hide()
		queue_free()
	else:
		error_label.text = Fmt.error_text(r)
		fit_to_content()


## Ô nhập số lượng theo tấn.
static func qty_input(max_t: float, initial_t: float, on_change: Callable) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = 0.0
	s.max_value = maxf(max_t, 0.0)
	s.step = 1.0
	s.value = clampf(initial_t, 0.0, s.max_value)
	s.suffix = "t"
	s.custom_minimum_size = Vector2(170, 0)
	s.select_all_on_focus = true
	s.value_changed.connect(func(_v: float) -> void: on_change.call())
	return s


static func info_row(grid: GridContainer, key: String, value_label: Label) -> void:
	grid.add_child(UI.label(Loc.t(key), "MutedLabel"))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(value_label)

class_name UI
extends RefCounted
## Hàm dựng widget nhanh để code giao diện ngắn gọn, đồng bộ phong cách.


static func label(text: String, variation: String = "", color: Color = Color(0, 0, 0, 0), size: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	if not variation.is_empty():
		l.theme_type_variation = variation
	if color.a > 0.0:
		l.add_theme_color_override("font_color", color)
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	return l


static func bold(text: String, color: Color = AppTheme.TEXT, size: int = 14) -> Label:
	var l := label(text, "", color, size)
	l.add_theme_font_override("font", AppTheme.font(true))
	return l


static func button(text: String, on_pressed: Callable, variation: String = "") -> Button:
	var b := Button.new()
	b.text = text
	if not variation.is_empty():
		b.theme_type_variation = variation
	b.focus_mode = Control.FOCUS_NONE
	# Kích hoạt khi nhấn xuống: bảng được làm mới liên tục nên tránh mất click.
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.pressed.connect(on_pressed)
	return b


static func hbox(sep: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func vbox(sep: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func grid(columns: int, hsep: int = 14, vsep: int = 6) -> GridContainer:
	var g := GridContainer.new()
	g.columns = columns
	g.add_theme_constant_override("h_separation", hsep)
	g.add_theme_constant_override("v_separation", vsep)
	return g


static func card(variation: String = "CardPanel") -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	return p


static func spacer(expand_h: bool = true) -> Control:
	var c := Control.new()
	if expand_h:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func sep() -> HSeparator:
	return HSeparator.new()


static func scroll(child: Control) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(child)
	return s


static func color_dot(color: Color, size: int = 10) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size = Vector2(size, size)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return r


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


## Ô số liệu: tiêu đề nhỏ + giá trị lớn.
static func stat(title: String, value: String, color: Color = AppTheme.TEXT) -> VBoxContainer:
	var v := vbox(0)
	v.add_child(label(title, "MutedLabel"))
	var val := bold(value, color, 17)
	val.name = "Value"
	v.add_child(val)
	return v


## Nhãn tự xuống dòng với chiều rộng cố định (bắt buộc trong hộp thoại để tính đúng chiều cao).
static func wrap_label(text: String, width: float, variation: String = "MutedLabel", color: Color = Color(0, 0, 0, 0)) -> Label:
	var l := label(text, variation, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l


static func small_button(text: String, on_pressed: Callable) -> Button:
	return button(text, on_pressed, "SmallButton")


static func right(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return l


static func progress(value: float, max_value: float = 1.0, color: Color = AppTheme.INFO, width: int = 120) -> ProgressBar:
	var p := ProgressBar.new()
	p.max_value = max_value
	p.value = value
	p.show_percentage = false
	p.custom_minimum_size = Vector2(width, 10)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fill := AppTheme.box(color, 4, Color(0, 0, 0, 0), 0, 0)
	p.add_theme_stylebox_override("fill", fill)
	return p

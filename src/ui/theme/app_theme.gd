class_name AppTheme
extends RefCounted
## Bảng màu + Theme dựng bằng code (dashboard tối, điểm nhấn vàng — theo ảnh concept).

const BG := Color("0b1424")
const PANEL := Color("12203a")
const PANEL_2 := Color("182a47")
const PANEL_3 := Color("1f3558")
const BORDER := Color("2a4468")
const TEXT := Color("e6edf7")
const MUTED := Color("8ea3c0")
const ACCENT := Color("e0b04a")
const GOOD := Color("3ecf8e")
const BAD := Color("f06464")
const WARN := Color("f0a43c")
const INFO := Color("4aa3e0")
const OCEAN := Color("0d2440")
const OCEAN_GRID := Color("163352")
const LAND := Color("24405a")
const LAND_EDGE := Color("33587a")

const FONT_NAMES: PackedStringArray = ["Segoe UI", "Roboto", "Noto Sans", "Helvetica Neue", "Arial", "DejaVu Sans", "Liberation Sans"]


static func font(bold: bool = false) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = FONT_NAMES
	f.font_weight = 700 if bold else 400
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	return f


static func box(color: Color, radius: int = 6, border: Color = Color(0, 0, 0, 0), border_width: int = 0, pad: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(border_width)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = maxi(2, pad - 3)
	s.content_margin_bottom = maxi(2, pad - 3)
	return s


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = font(false)
	t.default_font_size = 14
	var bold := font(true)
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", BG)
	t.set_color("font_disabled_color", "Button", MUTED.darkened(0.3))
	t.set_color("font_focus_color", "Button", TEXT)
	t.set_stylebox("normal", "Button", box(PANEL_3, 5, BORDER, 1))
	t.set_stylebox("hover", "Button", box(PANEL_3.lightened(0.12), 5, ACCENT.darkened(0.2), 1))
	t.set_stylebox("pressed", "Button", box(ACCENT, 5, ACCENT, 1))
	t.set_stylebox("disabled", "Button", box(PANEL_2, 5, PANEL_3, 1))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	# Nút điều hướng trái
	t.set_type_variation("NavButton", "Button")
	t.set_stylebox("normal", "NavButton", box(Color(0, 0, 0, 0), 6, Color(0, 0, 0, 0), 0, 12))
	t.set_stylebox("hover", "NavButton", box(PANEL_3, 6, Color(0, 0, 0, 0), 0, 12))
	t.set_stylebox("pressed", "NavButton", box(PANEL_3, 6, ACCENT, 0, 12))
	t.set_color("font_pressed_color", "NavButton", ACCENT)
	t.set_font("font", "NavButton", bold)
	t.set_font_size("font_size", "NavButton", 15)
	# Nút nhỏ trong bảng
	t.set_type_variation("SmallButton", "Button")
	t.set_stylebox("normal", "SmallButton", box(PANEL_3, 4, BORDER, 1, 6))
	t.set_stylebox("hover", "SmallButton", box(PANEL_3.lightened(0.12), 4, ACCENT.darkened(0.2), 1, 6))
	t.set_stylebox("pressed", "SmallButton", box(ACCENT, 4, ACCENT, 1, 6))
	t.set_stylebox("disabled", "SmallButton", box(PANEL_2, 4, PANEL_2, 1, 6))
	t.set_font_size("font_size", "SmallButton", 12)
	# Nút chính (vàng)
	t.set_type_variation("AccentButton", "Button")
	t.set_stylebox("normal", "AccentButton", box(ACCENT.darkened(0.1), 5))
	t.set_stylebox("hover", "AccentButton", box(ACCENT.lightened(0.1), 5))
	t.set_stylebox("pressed", "AccentButton", box(ACCENT.darkened(0.3), 5))
	t.set_stylebox("disabled", "AccentButton", box(PANEL_2, 5, PANEL_3, 1))
	t.set_color("font_color", "AccentButton", BG)
	t.set_color("font_hover_color", "AccentButton", BG)
	t.set_font("font", "AccentButton", bold)
	# Ô bảng giá có thể bấm
	t.set_type_variation("CellButton", "Button")
	t.set_stylebox("normal", "CellButton", box(PANEL_2, 4, Color(0, 0, 0, 0), 0, 6))
	t.set_stylebox("hover", "CellButton", box(PANEL_3, 4, ACCENT.darkened(0.3), 1, 6))
	t.set_stylebox("pressed", "CellButton", box(PANEL_3, 4, ACCENT, 2, 6))
	t.set_color("font_pressed_color", "CellButton", TEXT)
	# Panel
	t.set_stylebox("panel", "PanelContainer", box(PANEL, 8, BORDER, 1, 12))
	t.set_type_variation("CardPanel", "PanelContainer")
	t.set_stylebox("panel", "CardPanel", box(PANEL_2, 8, BORDER, 1, 12))
	t.set_type_variation("BarPanel", "PanelContainer")
	t.set_stylebox("panel", "BarPanel", box(PANEL, 0, BORDER, 0, 10))
	t.set_type_variation("HeaderLabel", "Label")
	t.set_font("font", "HeaderLabel", bold)
	t.set_font_size("font_size", "HeaderLabel", 20)
	t.set_color("font_color", "HeaderLabel", TEXT)
	t.set_type_variation("SubHeaderLabel", "Label")
	t.set_font("font", "SubHeaderLabel", bold)
	t.set_font_size("font_size", "SubHeaderLabel", 15)
	t.set_color("font_color", "SubHeaderLabel", ACCENT)
	t.set_type_variation("MutedLabel", "Label")
	t.set_color("font_color", "MutedLabel", MUTED)
	t.set_font_size("font_size", "MutedLabel", 13)
	# Ô nhập
	for type_name: String in ["LineEdit", "SpinBox"]:
		t.set_stylebox("normal", type_name, box(BG, 4, BORDER, 1))
		t.set_stylebox("focus", type_name, box(BG, 4, ACCENT, 1))
	t.set_color("font_color", "LineEdit", TEXT)
	# OptionButton / PopupMenu
	t.set_stylebox("normal", "OptionButton", box(PANEL_3, 5, BORDER, 1))
	t.set_stylebox("hover", "OptionButton", box(PANEL_3.lightened(0.1), 5, ACCENT.darkened(0.2), 1))
	t.set_stylebox("pressed", "OptionButton", box(PANEL_3, 5, ACCENT, 1))
	t.set_stylebox("focus", "OptionButton", StyleBoxEmpty.new())
	t.set_stylebox("panel", "PopupMenu", box(PANEL_2, 6, BORDER, 1))
	t.set_stylebox("hover", "PopupMenu", box(PANEL_3, 4))
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", ACCENT)
	# Thanh tiến độ
	t.set_stylebox("background", "ProgressBar", box(BG, 4, BORDER, 1, 0))
	t.set_stylebox("fill", "ProgressBar", box(INFO, 4, Color(0, 0, 0, 0), 0, 0))
	t.set_color("font_color", "ProgressBar", TEXT)
	# Cửa sổ / hộp thoại
	var win := box(PANEL, 8, ACCENT.darkened(0.3), 2, 14)
	win.expand_margin_left = 12
	win.expand_margin_right = 12
	win.expand_margin_bottom = 12
	win.expand_margin_top = 40
	t.set_stylebox("embedded_border", "Window", win)
	var win_u: StyleBoxFlat = win.duplicate()
	win_u.border_color = BORDER
	t.set_stylebox("embedded_unfocused_border", "Window", win_u)
	t.set_color("title_color", "Window", ACCENT)
	t.set_font("title_font", "Window", bold)
	t.set_font_size("title_font_size", "Window", 16)
	t.set_constant("title_height", "Window", 34)
	t.set_stylebox("panel", "AcceptDialog", box(PANEL, 0, Color(0, 0, 0, 0), 0, 14))
	# Cuộn
	t.set_stylebox("scroll", "VScrollBar", box(PANEL, 4, Color(0, 0, 0, 0), 0, 0))
	t.set_stylebox("grabber", "VScrollBar", box(PANEL_3, 4, Color(0, 0, 0, 0), 0, 0))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(BORDER, 4, Color(0, 0, 0, 0), 0, 0))
	t.set_stylebox("separator", "HSeparator", box(BORDER, 0, Color(0, 0, 0, 0), 0, 0))
	t.set_constant("separation", "HSeparator", 10)
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_stylebox("panel", "TooltipPanel", box(PANEL_3, 4, BORDER, 1))
	return t

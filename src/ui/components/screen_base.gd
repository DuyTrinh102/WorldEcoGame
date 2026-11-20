class_name ScreenBase
extends MarginContainer
## Lớp cơ sở cho một màn hình ở khu vực trung tâm. Module đăng ký màn hình qua
## ModuleContext.register_ui_screen(); MainUI tạo, hiển thị và gọi refresh() khi state đổi.

var main: MainUI


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side: String in ["left", "right", "top", "bottom"]:
		add_theme_constant_override("margin_" + side, 16)


## Gọi một lần sau khi main được gán.
func setup() -> void:
	pass


## Cập nhật dữ liệu hiển thị (được gọi khi màn hình đang hiện và state thay đổi).
func refresh() -> void:
	pass


func session() -> Node:
	return main.session


func world() -> WorldState:
	return main.session.world()


func content() -> ContentRegistry:
	return main.session.content


func company() -> String:
	return main.session.company_id()


func header(title_key: String, subtitle_key: String = "") -> VBoxContainer:
	var v := UI.vbox(2)
	v.add_child(UI.label(Loc.t(title_key), "HeaderLabel"))
	if not subtitle_key.is_empty():
		v.add_child(UI.label(Loc.t(subtitle_key), "MutedLabel"))
	return v

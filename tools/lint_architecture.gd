extends SceneTree
## Kiểm tra luật phân lớp (docs/ARCHITECTURE.md §2):
##  - Code mô phỏng (core, content, kernel, persistence, modules/*/sim, module manifest) không được
##    kế thừa Node/Control, không dùng get_tree()/autoload (GameSession, SimBridge), không tham chiếu UI.
##  - Code mô phỏng không dùng RNG toàn cục (randf/randi/randomize) hay thời gian thực.
##   godot --headless --path . -s res://tools/lint_architecture.gd

const SIM_DIRS: Array[String] = ["res://src/core", "res://src/content", "res://src/kernel", "res://src/persistence"]
const UI_CLASSES: Array[String] = ["MainUI", "ScreenBase", "WorldMap", "TopBar", "CountryPanel", "FormDialog", "TradeDialog", "ShipDialog", "BuildFactoryDialog", "UI.", "Fmt.", "AppTheme", "LineChart", "Loc."]
const FORBIDDEN: Array[String] = ["extends Node", "extends Control", "extends Container", "get_tree()", "GameSession", "SimBridge", "res://src/ui/", "/ui/"]
const NON_DETERMINISTIC: Array[String] = ["randf()", "randi()", "randomize()", "randf_range(", "randi_range(", "Time.get_ticks", "OS.get_unix_time"]
## Ngoại lệ có chủ đích (đường dẫn file -> lý do).
const ALLOW: Dictionary = {
	"res://src/persistence/save_format.gd": "Time.get_unix_time_from_system chỉ ghi vào header save, không ảnh hưởng mô phỏng",
}


func _init() -> void:
	var files: Array[String] = []
	for d in SIM_DIRS:
		_collect(d, files, false)
	for m in DirAccess.get_directories_at("res://src/modules"):
		var base: String = "res://src/modules/" + m
		_collect(base.path_join("sim"), files, false)
		for f in DirAccess.get_files_at(base):
			if f.ends_with(".gd"):
				files.append(base.path_join(f))
	var problems: Array[String] = []
	for path in files:
		var text: String = FileAccess.get_file_as_string(path)
		var lines: PackedStringArray = text.split("\n")
		for i in lines.size():
			var line: String = lines[i]
			var code: String = line.split("#")[0]
			for token in FORBIDDEN:
				if code.contains(token) and not (token == "/ui/" and code.contains("register_ui_screen")):
					problems.append("%s:%d  phụ thuộc UI/Node: '%s'" % [path, i + 1, token])
			for token in UI_CLASSES:
				if code.contains(token):
					problems.append("%s:%d  dùng lớp UI: '%s'" % [path, i + 1, token])
			if not ALLOW.has(path):
				for token in NON_DETERMINISTIC:
					# rng.randf_range(...) qua RandomNumberGenerator thì hợp lệ.
					if code.contains(token) and not code.contains("rng.") and not code.contains("rng(") :
						problems.append("%s:%d  không tất định: '%s'" % [path, i + 1, token])
	if problems.is_empty():
		print("Kiến trúc OK: %d file mô phỏng không phụ thuộc UI/Node và không dùng RNG toàn cục." % files.size())
	else:
		for p in problems:
			printerr("  ✗ ", p)
	quit(0 if problems.is_empty() else 1)


func _collect(dir: String, out: Array[String], _unused: bool) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_collect(dir.path_join(d), out, false)

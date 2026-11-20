class_name ContentLoader
extends RefCounted
## Nạp dữ liệu từ nhiều thư mục gốc theo thứ tự ưu tiên: base -> dlc -> mods.
## File ở gốc sau ghi đè định nghĩa cùng ID; nếu có "$patch": true thì chỉ trộn các trường.

const DEFAULT_ROOTS: Array[String] = ["res://data/base"]

var errors: Array[String] = []


static func load_default() -> ContentLoader:
	var loader := ContentLoader.new()
	loader.registry = loader.load_roots(DEFAULT_ROOTS)
	return loader


var registry: ContentRegistry


func load_roots(roots: Array[String]) -> ContentRegistry:
	errors.clear()
	var raw: Dictionary = {"commodities": {}, "countries": {}, "facilities": {}, "scenarios": {}}
	var accounts_raw: Array = []
	var settings: Dictionary = {}
	var modules: Array = []
	for root in roots:
		for folder: String in raw.keys():
			_merge_folder(root.path_join(folder), raw[folder])
		var acc: Variant = _read_json(root.path_join("accounts.json"), false)
		if acc is Array:
			accounts_raw = acc
		var st: Variant = _read_json(root.path_join("settings.json"), false)
		if st is Dictionary:
			settings = _deep_merge(settings, st)
		var mods: Variant = _read_json(root.path_join("modules.json"), false)
		if mods is Array:
			modules = mods
	var reg := ContentRegistry.new()
	reg.settings = settings
	for d: Dictionary in raw["commodities"].values():
		var c := CommodityDef.from_dict(d, errors)
		reg.commodities[c.id] = c
	for d: Dictionary in raw["countries"].values():
		var c := CountryDef.from_dict(d, errors)
		reg.countries[c.id] = c
	for d: Dictionary in raw["facilities"].values():
		var f := FacilityDef.from_dict(d, errors)
		reg.facilities[f.id] = f
	for d: Dictionary in raw["scenarios"].values():
		reg.scenarios[str(d.get("id", ""))] = d
	for d: Variant in accounts_raw:
		var a := AccountDef.from_dict(d as Dictionary, errors)
		reg.accounts[a.id] = a
	for m: Variant in modules:
		if m is Dictionary and (m as Dictionary).has("id") and (m as Dictionary).has("script"):
			reg.modules.append(m as Dictionary)
		else:
			errors.append("modules.json: mỗi phần tử cần 'id' và 'script'")
	reg.finalize()
	errors.append_array(ContentValidator.validate(reg))
	return reg


func _merge_folder(dir_path: String, into: Dictionary) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	var files: PackedStringArray = DirAccess.get_files_at(dir_path)
	var sorted: Array = Array(files)
	sorted.sort()
	for file: String in sorted:
		if not file.ends_with(".json"):
			continue
		var d: Variant = _read_json(dir_path.path_join(file), true)
		if not d is Dictionary:
			continue
		var dict: Dictionary = d
		var id: String = str(dict.get("id", ""))
		if id.is_empty():
			errors.append("%s: thiếu 'id'" % file)
			continue
		if bool(dict.get("$patch", false)) and into.has(id):
			into[id] = _deep_merge(into[id], dict)
		else:
			into[id] = dict


func _read_json(path: String, required: bool) -> Variant:
	if not FileAccess.file_exists(path):
		if required:
			errors.append("Không tìm thấy file: %s" % path)
		return null
	var text: String = FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK:
		errors.append("%s:%d — JSON lỗi: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


static func _deep_merge(base: Dictionary, over: Dictionary) -> Dictionary:
	var out: Dictionary = base.duplicate(true)
	for k: Variant in over:
		if k == "$patch":
			continue
		if out.has(k) and out[k] is Dictionary and over[k] is Dictionary:
			out[k] = _deep_merge(out[k], over[k])
		else:
			out[k] = over[k]
	return out

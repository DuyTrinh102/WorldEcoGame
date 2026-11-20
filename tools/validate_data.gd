extends SceneTree
## Kiểm tra toàn bộ dữ liệu game (schema tối thiểu + tham chiếu chéo + bản dịch).
##   godot --headless --path . -s res://tools/validate_data.gd


func _init() -> void:
	var loader := ContentLoader.new()
	var reg: ContentRegistry = loader.load_roots(ContentLoader.DEFAULT_ROOTS)
	var errors: Array[String] = loader.errors.duplicate()
	var vi: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/base/localization/vi.json"))
	if not vi is Dictionary:
		errors.append("localization/vi.json không hợp lệ")
	else:
		var keys: Array[String] = []
		for id in reg.commodity_ids:
			keys.append(reg.commodity(id).name_key)
		for id in reg.country_ids:
			keys.append(reg.country(id).name_key)
			keys.append("REGION_" + reg.country(id).region.to_upper())
		for id in reg.facility_ids:
			keys.append(reg.facility(id).name_key)
			keys.append(reg.facility(id).description_key)
		for id in reg.account_ids:
			keys.append(reg.account(id).name_key)
		for k in keys:
			if not (vi as Dictionary).has(k):
				errors.append("Thiếu bản dịch vi: " + k)
	for m: Dictionary in reg.modules:
		if not ResourceLoader.exists(str(m["script"])):
			errors.append("Module %s: không tìm thấy %s" % [m["id"], m["script"]])
	if errors.is_empty():
		print("Dữ liệu hợp lệ: %d quốc gia, %d hàng hóa, %d nhà máy, %d tài khoản, %d module." % [reg.country_ids.size(), reg.commodity_ids.size(), reg.facility_ids.size(), reg.account_ids.size(), reg.modules.size()])
	else:
		for e in errors:
			printerr("  ✗ ", e)
		printerr("%d lỗi dữ liệu." % errors.size())
	quit(0 if errors.is_empty() else 1)

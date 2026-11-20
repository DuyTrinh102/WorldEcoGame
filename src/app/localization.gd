class_name Loc
extends RefCounted
## Đa ngôn ngữ: nạp data/base/localization/<locale>.json vào TranslationServer.
## Dùng JSON thay vì CSV để không cần bước import của editor.

static var _loaded: Dictionary = {}


static func load_locale(locale: String = "vi") -> void:
	if not _loaded.has(locale):
		var path: String = "res://data/base/localization/%s.json" % locale
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		if data is Dictionary:
			var t := Translation.new()
			t.locale = locale
			for k: Variant in data:
				t.add_message(str(k), str(data[k]))
			TranslationServer.add_translation(t)
			_loaded[locale] = true
		else:
			push_warning("Không nạp được bản dịch: " + path)
	TranslationServer.set_locale(locale)


static func t(key: String, args: Dictionary = {}) -> String:
	var s: String = String(TranslationServer.translate(key))
	return s.format(args) if not args.is_empty() else s

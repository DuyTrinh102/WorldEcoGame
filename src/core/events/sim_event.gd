class_name SimEvent
extends RefCounted
## Domain event phát ra từ mô phỏng. UI/tin tức/module khác lắng nghe.
## `text_key` + `data` dùng để tạo dòng tin; trường kết thúc bằng `_cents`/`_qty`
## và trường `commodity`/`country` được UI định dạng tự động.

enum Importance { LOW, NORMAL, HIGH }

var type: String = ""
var day: int = 0
var company_id: String = ""
var importance: int = Importance.NORMAL
var text_key: String = ""
var data: Dictionary = {}


static func create(event_type: String, event_day: int, event_data: Dictionary = {}, key: String = "", level: int = Importance.NORMAL, company: String = "") -> SimEvent:
	var e := SimEvent.new()
	e.type = event_type
	e.day = event_day
	e.data = event_data
	e.text_key = key
	e.importance = level
	e.company_id = company
	return e


func to_dict() -> Dictionary:
	return {"type": type, "day": day, "company": company_id, "importance": importance, "text_key": text_key, "data": data}

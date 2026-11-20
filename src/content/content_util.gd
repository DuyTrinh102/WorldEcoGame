class_name ContentUtil
extends RefCounted
## Hàm hỗ trợ kiểm tra trường bắt buộc khi đọc dữ liệu.


static func req_str(d: Dictionary, key: String, errors: Array[String], ctx: String) -> String:
	if not d.has(key) or str(d[key]).is_empty():
		errors.append("%s: thiếu trường '%s'" % [ctx, key])
		return ""
	return str(d[key])


static func req_float(d: Dictionary, key: String, errors: Array[String], ctx: String) -> float:
	if not d.has(key):
		errors.append("%s: thiếu trường '%s'" % [ctx, key])
		return 0.0
	var v: Variant = d[key]
	if v is String:
		return (v as String).to_float()
	if v is float or v is int:
		return float(v)
	errors.append("%s: trường '%s' phải là số" % [ctx, key])
	return 0.0

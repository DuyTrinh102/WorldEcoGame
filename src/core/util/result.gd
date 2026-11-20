class_name Result
extends RefCounted
## Kết quả của validate/command: ok hoặc lỗi kèm mã thông điệp (key dịch) và tham số.

var ok: bool = true
var error_key: String = ""
var args: Dictionary = {}
var value: Variant = null


static func success(result_value: Variant = null) -> Result:
	var r := Result.new()
	r.value = result_value
	return r


static func fail(key: String, error_args: Dictionary = {}) -> Result:
	var r := Result.new()
	r.ok = false
	r.error_key = key
	r.args = error_args
	return r


func _to_string() -> String:
	return "OK" if ok else "ERR(%s %s)" % [error_key, args]

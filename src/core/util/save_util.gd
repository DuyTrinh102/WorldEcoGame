class_name SaveUtil
extends RefCounted
## Đọc giá trị từ Dictionary đã qua JSON (JSON biến số nguyên thành float) với kiểu rõ ràng.


static func i(d: Dictionary, key: String, default_value: int = 0) -> int:
	return int(d.get(key, default_value))


static func f(d: Dictionary, key: String, default_value: float = 0.0) -> float:
	return float(d.get(key, default_value))


static func s(d: Dictionary, key: String, default_value: String = "") -> String:
	return str(d.get(key, default_value))


static func b(d: Dictionary, key: String, default_value: bool = false) -> bool:
	return bool(d.get(key, default_value))


static func dict(d: Dictionary, key: String) -> Dictionary:
	var v: Variant = d.get(key, {})
	return v if v is Dictionary else {}


static func arr(d: Dictionary, key: String) -> Array:
	var v: Variant = d.get(key, [])
	return v if v is Array else []


## Dictionary<String, number> -> Dictionary<String, int>
static func int_map(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k: Variant in d:
		out[str(k)] = int(d[k])
	return out


static func float_list(a: Array) -> Array[float]:
	var out: Array[float] = []
	for v: Variant in a:
		out.append(float(v))
	return out


## Số thực lưu dạng nhị phân base64 (JSON của Godot không khứ hồi float chính xác tuyệt đối,
## mà mô phỏng cần tất định: lưu/tải giữa chừng phải cho kết quả y hệt).
static func floats_to_b64(values: Array) -> String:
	return Marshalls.raw_to_base64(PackedFloat64Array(values).to_byte_array())


static func b64_to_floats(text: String) -> PackedFloat64Array:
	if text.is_empty():
		return PackedFloat64Array()
	return Marshalls.base64_to_raw(text).to_float64_array()

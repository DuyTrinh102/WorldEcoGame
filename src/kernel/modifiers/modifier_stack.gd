class_name ModifierStack
extends RefCounted
## Tập modifier đang hiệu lực. System hỏi resolve(targets, stat, base) thay vì tự xử lý từng nguồn.
## Thứ tự áp dụng: cộng (ADD) trước, nhân (MULTIPLY) sau.

var _mods: Array[Modifier] = []


func add(m: Modifier) -> void:
	_mods.append(m)


func remove_by_source(source: String) -> void:
	_mods = _mods.filter(func(m: Modifier) -> bool: return m.source != source)


func remove_expired(day: int) -> void:
	_mods = _mods.filter(func(m: Modifier) -> bool: return m.end_day < 0 or m.end_day >= day)


func all() -> Array[Modifier]:
	return _mods


func resolve(targets: Array[String], stat: String, base: float, day: int) -> float:
	var add_total: float = 0.0
	var mul_total: float = 1.0
	for m in _mods:
		if m.stat != stat or not m.is_active(day) or not targets.has(m.target):
			continue
		if m.op == Modifier.Op.ADD:
			add_total += m.value
		else:
			mul_total *= m.value
	return (base + add_total) * mul_total


func to_array() -> Array:
	var out: Array = []
	for m in _mods:
		out.append(m.to_dict())
	return out


func from_array(a: Array) -> void:
	_mods.clear()
	for d: Variant in a:
		_mods.append(Modifier.from_dict(d as Dictionary))

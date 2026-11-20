class_name ModuleRegistry
extends RefCounted
## Nạp module theo cấu hình và sắp xếp theo phụ thuộc (topological sort, phát hiện vòng).


static func instantiate(entries: Array[Dictionary]) -> Array[SimModule]:
	var out: Array[SimModule] = []
	for e in entries:
		var script: Script = load(str(e["script"]))
		assert(script != null, "Không nạp được module: %s" % e["script"])
		var m: SimModule = script.new()
		assert(m.get_id() == str(e["id"]), "ID module không khớp: %s" % e["id"])
		out.append(m)
	return out


static func sort_by_dependencies(mods: Array[SimModule]) -> Array[SimModule]:
	var by_id: Dictionary = {}
	for m in mods:
		assert(not by_id.has(m.get_id()), "Module trùng ID: " + m.get_id())
		by_id[m.get_id()] = m
	var sorted: Array[SimModule] = []
	var state: Dictionary = {}  # id -> 1 đang duyệt, 2 xong
	for m in mods:
		_visit(m, by_id, state, sorted)
	return sorted


static func _visit(m: SimModule, by_id: Dictionary, state: Dictionary, out: Array[SimModule]) -> void:
	var id: String = m.get_id()
	if int(state.get(id, 0)) == 2:
		return
	assert(int(state.get(id, 0)) != 1, "Phụ thuộc vòng giữa các module tại: " + id)
	state[id] = 1
	for dep in m.get_dependencies():
		assert(by_id.has(dep), "Module %s cần module %s nhưng chưa được bật" % [id, dep])
		_visit(by_id[dep], by_id, state, out)
	state[id] = 2
	out.append(m)


## Kiểm tra không dùng assert (cho test/tool): trả về thông báo lỗi hoặc "".
static func find_dependency_error(mods: Array[SimModule]) -> String:
	var by_id: Dictionary = {}
	for m in mods:
		by_id[m.get_id()] = m
	for m in mods:
		for dep in m.get_dependencies():
			if not by_id.has(dep):
				return "missing:%s->%s" % [m.get_id(), dep]
	var state: Dictionary = {}
	for m in mods:
		var err: String = _check_cycle(m, by_id, state)
		if not err.is_empty():
			return err
	return ""


static func _check_cycle(m: SimModule, by_id: Dictionary, state: Dictionary) -> String:
	var id: String = m.get_id()
	if int(state.get(id, 0)) == 2:
		return ""
	if int(state.get(id, 0)) == 1:
		return "cycle:" + id
	state[id] = 1
	for dep in m.get_dependencies():
		var err: String = _check_cycle(by_id[dep], by_id, state)
		if not err.is_empty():
			return err
	state[id] = 2
	return ""

class_name SaveService
extends RefCounted
## Lưu/tải game. Ghi ra file tạm rồi đổi tên để tránh hỏng save khi crash.

const SAVE_DIR: String = "user://saves"


static func slot_path(slot: String) -> String:
	return SAVE_DIR.path_join(slot + ".sav")


static func to_save(sim: Simulation) -> Dictionary:
	return {"header": SaveFormat.make_header(sim), "data": sim.to_save_dict()}


static func encode(save: Dictionary) -> String:
	return JSON.stringify(save, "", true, true)


static func decode(text: String) -> Result:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return Result.fail("ERR_SAVE_CORRUPT")
	return SaveMigrations.migrate(json.data as Dictionary)


static func save_to_file(sim: Simulation, path: String) -> Result:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var tmp: String = path + ".tmp"
	var f: FileAccess = FileAccess.open_compressed(tmp, FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	if f == null:
		return Result.fail("ERR_SAVE_WRITE")
	f.store_string(encode(to_save(sim)))
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if DirAccess.rename_absolute(tmp, path) != OK:
		return Result.fail("ERR_SAVE_WRITE")
	return Result.success(path)


## Tải vào một Simulation đã tạo sẵn (cùng bộ module). Trả về header khi thành công.
static func load_from_file(sim: Simulation, path: String) -> Result:
	if not FileAccess.file_exists(path):
		return Result.fail("ERR_SAVE_NOT_FOUND")
	var f: FileAccess = FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_GZIP)
	if f == null:
		return Result.fail("ERR_SAVE_CORRUPT")
	var text: String = f.get_as_text()
	f.close()
	var decoded: Result = decode(text)
	if not decoded.ok:
		return decoded
	sim.load_save_dict(decoded.value["data"])
	return Result.success(decoded.value["header"])


static func read_header(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_GZIP)
	if f == null:
		return {}
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK or not json.data is Dictionary:
		return {}
	return SaveUtil.dict(json.data, "header")

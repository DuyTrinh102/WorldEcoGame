class_name SaveMigrations
extends RefCounted
## Chuỗi migration: save version N được nâng lần lượt N -> N+1 -> ... -> CURRENT_VERSION.
## Thêm bước mới: tạo file migrations/mXXX_to_YYY.gd (extends SaveMigration) và đăng ký vào STEPS.

## from_version -> đường dẫn script migration
const STEPS: Dictionary = {
	# 1: "res://src/persistence/migrations/m001_to_002.gd",
}


static func migrate(save: Dictionary, steps: Dictionary = STEPS, target: int = SaveFormat.CURRENT_VERSION) -> Result:
	var header: Dictionary = SaveUtil.dict(save, "header").duplicate(true)
	var version: int = SaveUtil.i(header, "save_version", 0)
	if version > target:
		return Result.fail("ERR_SAVE_TOO_NEW", {"version": version})
	var data: Dictionary = SaveUtil.dict(save, "data").duplicate(true)
	while version < target:
		if not steps.has(version):
			return Result.fail("ERR_SAVE_NO_MIGRATION", {"version": version})
		var step: Variant = steps[version]
		var migration: SaveMigration = (load(step) as Script).new() if step is String else step
		data = migration.migrate(data)
		version += 1
	header["save_version"] = version
	return Result.success({"header": header, "data": data})

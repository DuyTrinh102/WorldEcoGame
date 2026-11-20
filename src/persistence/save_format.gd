class_name SaveFormat
extends RefCounted
## Định dạng save: JSON nén gzip = {header, data}. Có version để migration.

## Tăng số này mỗi khi cấu trúc save thay đổi và thêm migration tương ứng.
const CURRENT_VERSION: int = 1
const GAME_VERSION: String = "0.2.0-prototype"


static func make_header(sim: Simulation) -> Dictionary:
	var player: Dictionary = CorporateQueries.player(sim.world)
	return {
		"save_version": CURRENT_VERSION,
		"game_version": GAME_VERSION,
		"day": sim.world.day,
		"company_name": str(player.get("name", "")),
		"saved_at_unix": int(Time.get_unix_time_from_system()),
	}

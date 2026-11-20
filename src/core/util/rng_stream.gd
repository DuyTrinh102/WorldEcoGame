class_name RngStream
extends RefCounted
## Luồng số ngẫu nhiên tất định: mỗi (seed, stream_id, day) cho ra một chuỗi riêng.
## Thêm system mới không làm lệch kết quả của system cũ.


static func create(world_seed: int, stream_id: String, day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = ("%d|%s|%d" % [world_seed, stream_id, day]).hash()
	return rng

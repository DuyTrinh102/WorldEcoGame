class_name WorldQueries
extends RefCounted
## API chỉ-đọc về quốc gia và địa lý.

const EARTH_RADIUS_KM: float = 6371.0


## Khoảng cách vòng lớn giữa hai cảng (km).
static func great_circle_km(content: ContentRegistry, a: String, b: String) -> float:
	var ca: CountryDef = content.country(a)
	var cb: CountryDef = content.country(b)
	var lat1: float = deg_to_rad(ca.lat)
	var lat2: float = deg_to_rad(cb.lat)
	var dlat: float = lat2 - lat1
	var dlon: float = deg_to_rad(cb.lon - ca.lon)
	var h: float = sin(dlat / 2.0) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2.0) ** 2
	return 2.0 * EARTH_RADIUS_KM * asin(minf(1.0, sqrt(h)))


## Khoảng cách đường biển ước lượng = vòng lớn × hệ số tuyến.
static func sea_distance_km(content: ContentRegistry, a: String, b: String) -> float:
	if a == b:
		return 0.0
	return great_circle_km(content, a, b) * content.setting_f("logistics.sea_route_factor", 1.3)


static func modifiers(world: WorldState) -> ModifierStack:
	return WorldModuleState.of(world).modifiers

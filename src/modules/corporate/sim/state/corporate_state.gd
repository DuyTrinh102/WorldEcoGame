class_name CorporateState
extends ModuleState

## company_id -> {id, name, home_country, is_player, color, founded_day}
var companies: Dictionary = {}


static func of(world: WorldState) -> CorporateState:
	return world.get_state("corporate") as CorporateState


func to_dict() -> Dictionary:
	return {"companies": companies.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	companies = {}
	var src: Dictionary = SaveUtil.dict(d, "companies")
	for k: Variant in src:
		var c: Dictionary = src[k]
		companies[str(k)] = {
			"id": SaveUtil.s(c, "id"),
			"name": SaveUtil.s(c, "name"),
			"home_country": SaveUtil.s(c, "home_country"),
			"is_player": SaveUtil.b(c, "is_player"),
			"color": SaveUtil.s(c, "color", "#e0b04a"),
			"founded_day": SaveUtil.i(c, "founded_day"),
		}

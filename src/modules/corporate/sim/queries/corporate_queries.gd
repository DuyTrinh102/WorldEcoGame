class_name CorporateQueries
extends RefCounted


static func company(world: WorldState, company_id: String) -> Dictionary:
	return CorporateState.of(world).companies.get(company_id, {})


static func exists(world: WorldState, company_id: String) -> bool:
	return CorporateState.of(world).companies.has(company_id)


static func player(world: WorldState) -> Dictionary:
	return company(world, world.player_company_id)


static func company_ids(world: WorldState) -> Array[String]:
	var out: Array[String] = []
	for k: Variant in CorporateState.of(world).companies:
		out.append(str(k))
	out.sort()
	return out

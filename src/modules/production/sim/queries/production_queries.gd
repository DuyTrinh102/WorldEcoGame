class_name ProductionQueries
extends RefCounted

const STATUS_BUILDING := "building"
const STATUS_RUNNING := "running"
const STATUS_NO_INPUT := "no_input"
const STATUS_PAUSED := "paused"


static func factories_of(world: WorldState, company_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var st: ProductionState = ProductionState.of(world)
	var ids: Array = st.factories.keys()
	ids.sort()
	for id: String in ids:
		if company_id.is_empty() or str(st.factories[id]["company"]) == company_id:
			out.append(st.factories[id])
	return out


static func factories_in(world: WorldState, company_id: String, country_id: String) -> Array[Dictionary]:
	return factories_of(world, company_id).filter(func(f: Dictionary) -> bool: return str(f["country"]) == country_id)


static func factory(world: WorldState, factory_id: String) -> Dictionary:
	return ProductionState.of(world).factories.get(factory_id, {})


## Ước tính biên lợi nhuận/đơn vị theo giá thị trường tại quốc gia (để người chơi ra quyết định).
static func unit_economics(world: WorldState, content: ContentRegistry, facility_id: String, country_id: String) -> Dictionary:
	var f: FacilityDef = content.facility(facility_id)
	var input_cost: float = 0.0
	for k: String in f.inputs:
		input_cost += float(f.inputs[k]) * MarketQueries.price(world, country_id, k)
	var var_cost: float = UnitPrice.to_float(f.variable_cost_per_unit)
	var out_price: float = MarketQueries.price(world, country_id, f.output)
	return {"input_cost": input_cost, "variable_cost": var_cost, "output_price": out_price, "margin": out_price - input_cost - var_cost}

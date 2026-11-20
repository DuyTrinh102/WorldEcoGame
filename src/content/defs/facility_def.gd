class_name FacilityDef
extends RefCounted
## Loại cơ sở sản xuất + công thức (BOM).

var id: String
var name_key: String
var description_key: String
var build_cost: int = 0          # cent
var build_days: int = 30
var capacity_per_day: int = 0    # Quantity (×1000) đầu ra mỗi ngày
## commodity_id -> lượng đầu vào cho 1 đơn vị đầu ra
var inputs: Dictionary = {}
var output: String = ""
var variable_cost_per_unit: int = 0  # UnitPrice (×1e4)
var monthly_overhead: int = 0        # cent
var depreciation_years: int = 10


static func from_dict(d: Dictionary, errors: Array[String]) -> FacilityDef:
	var f := FacilityDef.new()
	f.id = ContentUtil.req_str(d, "id", errors, "facility")
	f.name_key = str(d.get("name_key", "FACILITY_" + f.id.to_upper()))
	f.description_key = str(d.get("description_key", ""))
	f.build_cost = Money.from_float(ContentUtil.req_float(d, "build_cost", errors, f.id))
	f.build_days = int(d.get("build_days", 30))
	f.capacity_per_day = Quantity.from_float(ContentUtil.req_float(d, "capacity_per_day", errors, f.id))
	var ins: Dictionary = d.get("inputs", {})
	if ins.is_empty():
		errors.append("%s: inputs không được rỗng" % f.id)
	for k: Variant in ins:
		f.inputs[str(k)] = float(ins[k])
	f.output = ContentUtil.req_str(d, "output", errors, f.id)
	f.variable_cost_per_unit = UnitPrice.from_float(float(d.get("variable_cost_per_unit", 0.0)))
	f.monthly_overhead = Money.from_float(float(d.get("monthly_overhead", 0.0)))
	f.depreciation_years = maxi(1, int(d.get("depreciation_years", 10)))
	return f

class_name ContentValidator
extends RefCounted
## Kiểm tra tham chiếu chéo giữa các định nghĩa (ID tồn tại, cung cầu khả thi...).

const REQUIRED_ACCOUNTS: Array[String] = [
	"cash", "receivables", "inventory", "inventory_transit", "fixed_assets",
	"accum_depreciation", "loans", "capital", "revenue", "cogs",
	"storage_expense", "factory_overhead", "depreciation", "interest_expense", "setup_expense",
]


static func validate(reg: ContentRegistry) -> Array[String]:
	var errors: Array[String] = []
	if reg.commodities.is_empty():
		errors.append("Không có hàng hóa nào")
	if reg.countries.is_empty():
		errors.append("Không có quốc gia nào")
	for cid in reg.country_ids:
		var c: CountryDef = reg.country(cid)
		for res: String in c.resources:
			if not reg.commodities.has(res):
				errors.append("Quốc gia %s: tài nguyên '%s' không tồn tại" % [cid, res])
		for res: String in c.demand_bias:
			if not reg.commodities.has(res):
				errors.append("Quốc gia %s: demand_bias '%s' không tồn tại" % [cid, res])
	# Mỗi hàng hóa phải được sản xuất ở ít nhất một quốc gia (để hiệu chỉnh cầu).
	for kid in reg.commodity_ids:
		var total: float = 0.0
		for cid in reg.country_ids:
			total += float(reg.country(cid).resources.get(kid, 0.0))
		if total <= 0.0:
			errors.append("Hàng hóa '%s' không có quốc gia nào sản xuất" % kid)
	for fid in reg.facility_ids:
		var f: FacilityDef = reg.facility(fid)
		if not reg.commodities.has(f.output):
			errors.append("Cơ sở %s: output '%s' không tồn tại" % [fid, f.output])
		for inp: String in f.inputs:
			if not reg.commodities.has(inp):
				errors.append("Cơ sở %s: input '%s' không tồn tại" % [fid, inp])
			elif float(f.inputs[inp]) <= 0.0:
				errors.append("Cơ sở %s: tỷ lệ input '%s' phải > 0" % [fid, inp])
	for acc in REQUIRED_ACCOUNTS:
		if not reg.accounts.has(acc):
			errors.append("Thiếu tài khoản kế toán bắt buộc: %s" % acc)
	for sid: String in reg.scenarios:
		var s: Dictionary = reg.scenarios[sid]
		var home: String = str(s.get("home_country", ""))
		if not reg.countries.has(home):
			errors.append("Kịch bản %s: home_country '%s' không tồn tại" % [sid, home])
		for w: Variant in s.get("start_warehouses", []):
			if not reg.countries.has(str(w)):
				errors.append("Kịch bản %s: kho khởi đầu ở '%s' không tồn tại" % [sid, w])
	if not reg.scenarios.has("default"):
		errors.append("Thiếu kịch bản 'default'")
	return errors

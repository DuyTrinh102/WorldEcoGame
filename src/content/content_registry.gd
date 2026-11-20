class_name ContentRegistry
extends RefCounted
## Kho định nghĩa tĩnh của game. Chỉ đọc sau khi nạp. Không lưu vào save (save chỉ lưu ID).

var commodities: Dictionary = {}   # id -> CommodityDef
var countries: Dictionary = {}     # id -> CountryDef
var facilities: Dictionary = {}    # id -> FacilityDef
var accounts: Dictionary = {}      # id -> AccountDef
var scenarios: Dictionary = {}     # id -> Dictionary
var settings: Dictionary = {}      # hằng số cân bằng game
var modules: Array[Dictionary] = []  # [{id, script}]

var commodity_ids: Array[String] = []
var country_ids: Array[String] = []
var facility_ids: Array[String] = []
var account_ids: Array[String] = []


func commodity(id: String) -> CommodityDef:
	return commodities.get(id) as CommodityDef


func country(id: String) -> CountryDef:
	return countries.get(id) as CountryDef


func facility(id: String) -> FacilityDef:
	return facilities.get(id) as FacilityDef


func account(id: String) -> AccountDef:
	return accounts.get(id) as AccountDef


## Đọc hằng số cân bằng theo đường dẫn "market.trade_rate".
func setting(path: String, default_value: Variant = null) -> Variant:
	var node: Variant = settings
	for part in path.split("."):
		if node is Dictionary and (node as Dictionary).has(part):
			node = (node as Dictionary)[part]
		else:
			return default_value
	return node


func setting_f(path: String, default_value: float = 0.0) -> float:
	return float(setting(path, default_value))


func setting_i(path: String, default_value: int = 0) -> int:
	return int(setting(path, default_value))


## Sắp xếp danh sách ID (đảm bảo duyệt tất định).
func finalize() -> void:
	commodity_ids = _sorted_keys(commodities)
	country_ids = _sorted_keys(countries)
	facility_ids = _sorted_keys(facilities)
	account_ids = []
	var accs: Array = accounts.values()
	accs.sort_custom(func(a: AccountDef, b: AccountDef) -> bool: return a.code < b.code)
	for a: AccountDef in accs:
		account_ids.append(a.id)


static func _sorted_keys(d: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for k: Variant in d:
		out.append(str(k))
	out.sort()
	return out

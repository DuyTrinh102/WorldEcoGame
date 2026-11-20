class_name CountryDef
extends RefCounted
## Hồ sơ quốc gia (đọc từ data/*/countries/*.json).

var id: String
var name_key: String
var currency: String
var region: String
var simulation_tier: String = "detailed"
var population: float = 0.0
var gdp_per_capita: float = 0.0
## Vị trí cảng chính (độ).
var port_name: String = ""
var lat: float = 0.0
var lon: float = 0.0
var color: Color = Color.WHITE
## commodity_id -> sản lượng năm (đơn vị của hàng hóa)
var resources: Dictionary = {}
## commodity_id -> hệ số khẩu vị tiêu dùng (mặc định 1.0)
var demand_bias: Dictionary = {}
var corporate_tax: float = 0.2
var political_risk: float = 0.2
var disaster_risk: float = 0.2


static func from_dict(d: Dictionary, errors: Array[String]) -> CountryDef:
	var c := CountryDef.new()
	c.id = ContentUtil.req_str(d, "id", errors, "country")
	c.name_key = str(d.get("name_key", "COUNTRY_" + c.id))
	c.currency = str(d.get("currency", "USD"))
	c.region = str(d.get("region", ""))
	c.simulation_tier = str(d.get("simulation_tier", "detailed"))
	c.color = Color.from_string(str(d.get("color", "#ffffff")), Color.WHITE)
	var macro: Dictionary = d.get("macro", {})
	c.population = float(macro.get("population", 0))
	c.gdp_per_capita = float(macro.get("gdp_per_capita_usd", 0))
	if c.population <= 0.0 or c.gdp_per_capita <= 0.0:
		errors.append("%s: macro.population và macro.gdp_per_capita_usd phải > 0" % c.id)
	var port: Dictionary = d.get("port", {})
	c.port_name = str(port.get("name", c.id))
	c.lat = float(port.get("lat", 0.0))
	c.lon = float(port.get("lon", 0.0))
	var res: Dictionary = d.get("resources", {})
	for k: Variant in res:
		c.resources[str(k)] = float(res[k])
	var bias: Dictionary = d.get("demand_bias", {})
	for k: Variant in bias:
		c.demand_bias[str(k)] = float(bias[k])
	c.corporate_tax = float(d.get("tax", {}).get("corporate", 0.2))
	var risk: Dictionary = d.get("risk", {})
	c.political_risk = float(risk.get("political", 0.2))
	c.disaster_risk = float(risk.get("natural_disaster", 0.2))
	return c

class_name DetailedMarketModel
extends RefCounted
## Mô hình thị trường chi tiết (theo ngày) — xem docs/ARCHITECTURE.md §4.6.
##   Cung khả dụng = tồn đầu kỳ + sản lượng + nhập khẩu − xuất khẩu
##   Cầu = cầu gốc × (P/P_ref)^ε_giá × modifier
##   Giá mục tiêu = P_ref × (ngày tồn kho / mục tiêu)^(−độ nhạy); giá thực tiến dần về mục tiêu.
## Thương mại quốc tế NPC: hàng chảy từ nơi giá thấp sang nơi giá cao, tổng xuất = tổng nhập.


## Hiệu chỉnh cầu gốc để tổng cầu thế giới = tổng cung ở giá tham chiếu; khởi tạo tồn kho mục tiêu.
static func initialize(st: MarketState, content: ContentRegistry) -> void:
	var target_cover: float = content.setting_f("market.target_cover_days", 90.0)
	st.markets.clear()
	for cid in content.country_ids:
		st.markets[cid] = {}
	for kid in content.commodity_ids:
		var c: CommodityDef = content.commodity(kid)
		var total_prod: float = 0.0
		var total_raw: float = 0.0
		var raw: Dictionary = {}
		for cid in content.country_ids:
			var country: CountryDef = content.country(cid)
			total_prod += float(country.resources.get(kid, 0.0))
			var r: float = country.population * pow(country.gdp_per_capita / 10000.0, c.income_elasticity) * float(country.demand_bias.get(kid, 1.0))
			raw[cid] = r
			total_raw += r
		var k_scale: float = total_prod / maxf(total_raw, 1e-9)
		for cid in content.country_ids:
			var prod: float = float(content.country(cid).resources.get(kid, 0.0))
			var cons: float = float(raw[cid]) * k_scale
			var scale: float = maxf(maxf(prod, cons), 1.0)
			st.markets[cid][kid] = {
				"price": c.base_price,
				"stock": scale / 365.0 * target_cover,
				"base_prod": prod,
				"base_cons": cons,
				"scale": scale,
				"price_ema": c.base_price,
				"month_open": c.base_price,
			}
		st.world_price[kid] = c.base_price


static func step_all(st: MarketState, ctx: TickContext, mods: ModifierStack) -> void:
	for kid in ctx.content.commodity_ids:
		step_commodity(st, ctx, mods, kid)


static func step_commodity(st: MarketState, ctx: TickContext, mods: ModifierStack, kid: String) -> void:
	var content: ContentRegistry = ctx.content
	var c: CommodityDef = content.commodity(kid)
	var ref: float = c.base_price
	var season: float = c.seasonality[GameDate.month(ctx.day) - 1]
	var target_cover: float = content.setting_f("market.target_cover_days", 90.0)
	var trade_rate: float = content.setting_f("market.trade_rate", 4.0)
	var noise: float = content.setting_f("market.noise", 0.004)
	var floor_ratio: float = content.setting_f("market.price_floor_ratio", 0.25)
	var cap_ratio: float = content.setting_f("market.price_cap_ratio", 4.0)
	var ema_days: float = content.setting_f("market.supply_ema_days", 90.0)
	var sensitivity: float = content.setting_f("market.stock_price_sensitivity", 1.2)
	var rng: RandomNumberGenerator = ctx.rng("market." + kid)
	var ids: Array[String] = content.country_ids
	var prod: Array[float] = []
	var dem: Array[float] = []
	var weighted_sum: float = 0.0
	var weight_total: float = 0.0
	for cid in ids:
		var e: Dictionary = st.markets[cid][kid]
		var targets: Array[String] = ["country:" + cid, "commodity:" + kid, "market:%s/%s" % [cid, kid]]
		var p: float = float(e["base_prod"]) / 365.0 * season * pow(float(e["price_ema"]) / ref, c.supply_elasticity)
		p *= 1.0 + rng.randf_range(-0.05, 0.05)
		prod.append(maxf(0.0, mods.resolve(targets, "market.production", p, ctx.day)))
		var d: float = float(e["base_cons"]) / 365.0 * pow(float(e["price"]) / ref, c.price_elasticity)
		dem.append(maxf(0.0, mods.resolve(targets, "market.demand", d, ctx.day)))
		weighted_sum += float(e["price"]) * float(e["scale"])
		weight_total += float(e["scale"])
	var world_price: float = weighted_sum / maxf(weight_total, 1e-9)
	st.world_price[kid] = world_price
	# Dòng thương mại mong muốn (dương = nhập khẩu).
	var desired: Array[float] = []
	var imp_total: float = 0.0
	var exp_total: float = 0.0
	for i in ids.size():
		var e: Dictionary = st.markets[ids[i]][kid]
		var flow: float = trade_rate * float(e["scale"]) / 365.0 * (float(e["price"]) - world_price) / world_price
		if flow < 0.0:
			flow = maxf(flow, -0.5 * (float(e["stock"]) + prod[i]))
			exp_total += -flow
		else:
			imp_total += flow
		desired.append(flow)
	var traded: float = minf(imp_total, exp_total)
	var imp_scale: float = traded / imp_total if imp_total > 0.0 else 0.0
	var exp_scale: float = traded / exp_total if exp_total > 0.0 else 0.0
	for i in ids.size():
		var e: Dictionary = st.markets[ids[i]][kid]
		var flow: float = desired[i] * (imp_scale if desired[i] > 0.0 else exp_scale)
		var stock: float = float(e["stock"]) + prod[i] + flow
		stock = maxf(0.0, stock - minf(dem[i], stock))
		e["stock"] = stock
		var cover: float = stock / (float(e["scale"]) / 365.0)
		# Giá mục tiêu là hàm của MỨC tồn kho (bộ điều khiển tỉ lệ — ổn định, có giảm chấn):
		# thiếu hàng -> giá cao, thừa hàng -> giá thấp.
		var target_price: float = ref * pow(maxf(cover, 1.0) / target_cover, -sensitivity)
		target_price = clampf(target_price, ref * floor_ratio, ref * cap_ratio)
		var price: float = float(e["price"])
		var change: float = clampf(c.adjust_speed * (target_price / price - 1.0), -c.max_daily_change, c.max_daily_change)
		change += rng.randfn(0.0, noise)
		price = clampf(price * (1.0 + change), ref * floor_ratio, ref * cap_ratio)
		e["price"] = price
		e["price_ema"] = float(e["price_ema"]) + (price - float(e["price_ema"])) / ema_days


## Độ sâu thị trường (đơn vị hàng) dùng để tính trượt giá khi người chơi giao dịch.
static func depth(content: ContentRegistry, e: Dictionary) -> float:
	return maxf(float(e["scale"]) / 365.0 * content.setting_f("market.trade_depth_days", 30.0), 1.0)

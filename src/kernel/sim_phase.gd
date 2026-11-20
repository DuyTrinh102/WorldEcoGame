class_name SimPhase
extends RefCounted
## Thứ tự phase cố định trong một tick (1 ngày) — ánh xạ "vòng lặp một tháng" của concept.

enum Phase {
	COMMANDS,      ## Áp dụng command trong hàng đợi (AI, kịch bản)
	MARKET,        ## Cung cầu, giá
	PRODUCTION,    ## Nhà máy tiêu hao nguyên liệu, tạo sản lượng
	LOGISTICS,     ## Hàng di chuyển, chuyến hàng đến nơi
	TRADE,         ## Giao hàng, công nợ, thu tiền
	FINANCE,       ## Lương, lãi vay, thuế, khấu hao, phí kho
	AGENTS,        ## AI ra quyết định, sự kiện thế giới
	PERIOD_CLOSE,  ## Chốt kỳ: báo cáo, KPI (cuối tháng)
	PUBLISH,       ## Phát domain event cho người nghe
}

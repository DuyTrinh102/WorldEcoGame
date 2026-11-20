# Nhật ký quyết định (ADR-lite)

Ghi lại các quyết định quan trọng để người sau (và Claude Code) hiểu *vì sao*. Mỗi quyết định: bối cảnh → quyết định → hệ quả. Trạng thái: `Đã chốt` / `Đề xuất` / `Cần xác nhận`.

---

## A. Quyết định kiến trúc

### ADR-001 · Godot 4.x + GDScript có kiểu tĩnh — `Đề xuất`
- **Bối cảnh:** Concept đề xuất Godot 4.x + GDScript; game 2D, UI dày, xuất Windows.
- **Quyết định:** Dùng GDScript, **bắt buộc static typing** (`var x: int`, kiểu trả về), bật cảnh báo untyped thành lỗi trong project settings.
- **Hệ quả:** Phát triển nhanh, Claude Code hỗ trợ tốt. Nếu một system nặng thành nút cổ chai → viết lại riêng system đó bằng C#/GDExtension, interface không đổi.

### ADR-002 · Tách mô phỏng khỏi UI, sim không kế thừa Node — `Đề xuất`
- **Quyết định:** `kernel/` và `modules/*/sim/` chỉ dùng `RefCounted`/`Resource`; UI giao tiếp qua `GameSession`, `Queries`, `SimBridge`.
- **Hệ quả:** Test headless, chạy cân bằng nhanh, có thể chạy sim trên thread hoặc server multiplayer.

### ADR-003 · Mọi thay đổi trạng thái qua Command — `Đề xuất`
- **Hệ quả:** AI dùng chung luật với người chơi; replay, scenario test, multiplayer khả thi. Chi phí: viết thêm class command cho mỗi hành động.

### ADR-004 · Kiến trúc module/plugin theo tính năng — `Đề xuất`
- **Quyết định:** Mỗi mảng là một thư mục `src/modules/<tên>/` với manifest `SimModule`; bật/tắt qua `data/base/modules.json`.
- **Hệ quả:** Tính năng sau 1.0 (banking, M&A, IPO) thêm vào không sửa lõi.

### ADR-005 · Tiền là số nguyên fixed-point — `Đề xuất`
- **Quyết định:** `Money` = int ×100, `UnitPrice` = int ×10 000, `Quantity` = int ×1 000. Float chỉ cho chỉ số vĩ mô không đi vào sổ cái.

### ADR-006 · Sổ cái kép là nguồn sự thật của tài chính — `Đề xuất`
- **Hệ quả:** Báo cáo luôn khớp nhau; lợi nhuận vs dòng tiền khác nhau một cách tự nhiên; sẵn cho hợp nhất báo cáo.

### ADR-007 · Mô phỏng tất định, RNG theo luồng từng system — `Đề xuất`

### ADR-008 · Save = JSON nén có version + migration chain; SQLite để sau — `Đề xuất`
- **Bối cảnh:** Concept gợi ý "SQLite hoặc định dạng save có version".
- **Quyết định:** JSON + gzip cho MVP (đơn giản, debug được, migration dễ). Xem xét SQLite khi cần lưu lịch sử dài hạn.

### ADR-009 · Thị trường hai mức chi tiết (Detailed / Aggregate) — `Đề xuất`
- **Hệ quả:** Hiển thị đủ quốc gia nhưng chỉ tốn CPU cho nơi có hoạt động.

### ADR-010 · gdUnit4 làm framework test — `Đề xuất`
- **Lý do:** Chạy được headless/CI, hỗ trợ GDScript tốt. (Thay thế: GUT.)

---

## B. Quyết định thiết kế game cần bạn xác nhận

Các mục này đến từ phần "Các quyết định thiết kế cần xác nhận" trong concept, kèm đề xuất mặc định để không chặn tiến độ.

| # | Câu hỏi | Đề xuất mặc định | Ảnh hưởng tới code |
|---|---------|------------------|--------------------|
| D-1 | Quy mô bản đồ | Hiển thị 195 quốc gia; mô phỏng chi tiết 30–50 (1.0); prototype 8 | `simulation_tier` trong JSON quốc gia |
| D-2 | Điểm bắt đầu | Người chơi chọn quốc gia + ngành + mức vốn (dễ / thường / khó) | `data/base/scenarios/*.json` |
| D-3 | Mức độ mô phỏng | Thế giới và AI hoạt động độc lập, không chờ người chơi | Đã phản ánh trong kernel |
| D-4 | Mục tiêu chơi | Sandbox không kết thúc + kịch bản có mục tiêu tùy chọn | Module `scenarios`/`objectives` (M5) |
| D-5 | Phong cách hình ảnh | Dashboard 2D + bản đồ thế giới + cảnh isometric cho nhà máy/cảng/kho | `ui/`, `assets/` |
| D-6 | Đơn vị thời gian | Tick = 1 ngày; chốt sổ theo tháng | `SimClock` |
| D-7 | Tiền tệ hạch toán | Mỗi công ty hạch toán theo tiền tệ quốc gia sở tại; tập đoàn hợp nhất về USD | `finance`, `world` (tỷ giá) |
| D-8 | Ngôn ngữ phát hành | Tiếng Việt + Tiếng Anh từ bản Alpha | `data/base/localization/` |
| D-9 | Engine & ngôn ngữ | Godot 4.x + GDScript (theo concept) | Toàn bộ |

# Nhật ký quyết định (ADR-lite)

Ghi lại các quyết định quan trọng để người sau (và Claude Code) hiểu *vì sao*. Mỗi quyết định: bối cảnh → quyết định → hệ quả. Trạng thái: `Đã chốt` / `Đề xuất` / `Cần xác nhận`.

---

## A. Quyết định kiến trúc

### ADR-001 · Godot 4.5 + GDScript có kiểu tĩnh — `Đã chốt`
- **Bối cảnh:** Concept đề xuất Godot 4.x + GDScript; game 2D, UI dày, xuất Windows.
- **Quyết định:** Dùng GDScript, **bắt buộc static typing** (`var x: int`, kiểu trả về), bật cảnh báo untyped thành lỗi trong project settings.
- **Hệ quả:** Phát triển nhanh, Claude Code hỗ trợ tốt. Nếu một system nặng thành nút cổ chai → viết lại riêng system đó bằng C#/GDExtension, interface không đổi.

### ADR-002 · Tách mô phỏng khỏi UI, sim không kế thừa Node — `Đã chốt` (kiểm tra tự động bởi `tools/lint_architecture.gd`)
- **Quyết định:** `kernel/` và `modules/*/sim/` chỉ dùng `RefCounted`/`Resource`; UI giao tiếp qua `GameSession`, `Queries`, `SimBridge`.
- **Hệ quả:** Test headless, chạy cân bằng nhanh, có thể chạy sim trên thread hoặc server multiplayer.

### ADR-003 · Mọi thay đổi trạng thái qua Command — `Đã chốt`
- Thao tác của người chơi được áp dụng ngay giữa hai tick (`Simulation.submit`) để phản hồi tức thì khi đang tạm dừng; command của AI/kịch bản xếp hàng (`enqueue`) và chạy ở phase COMMANDS.
- **Hệ quả:** AI dùng chung luật với người chơi; replay, scenario test, multiplayer khả thi. Chi phí: viết thêm class command cho mỗi hành động.

### ADR-004 · Kiến trúc module/plugin theo tính năng — `Đã chốt`
- **Quyết định:** Mỗi mảng là một thư mục `src/modules/<tên>/` với manifest `SimModule`; bật/tắt qua `data/base/modules.json`.
- **Hệ quả:** Tính năng sau 1.0 (banking, M&A, IPO) thêm vào không sửa lõi.

### ADR-005 · Tiền là số nguyên fixed-point — `Đã chốt`
- **Quyết định:** `Money` = int ×100, `UnitPrice` = int ×10 000, `Quantity` = int ×1 000. Float chỉ cho chỉ số vĩ mô không đi vào sổ cái.

### ADR-006 · Sổ cái kép là nguồn sự thật của tài chính — `Đã chốt`
- **Hệ quả:** Báo cáo luôn khớp nhau; lợi nhuận vs dòng tiền khác nhau một cách tự nhiên; sẵn cho hợp nhất báo cáo.

### ADR-007 · Mô phỏng tất định, RNG theo luồng từng system — `Đã chốt` (test: lưu/tải giữa chừng cho hash trạng thái giống hệt chạy liên tục)

### ADR-008 · Save = JSON nén có version + migration chain; SQLite để sau — `Đã chốt`
- **Bối cảnh:** Concept gợi ý "SQLite hoặc định dạng save có version".
- **Quyết định:** JSON + gzip cho MVP (đơn giản, debug được, migration dễ). Xem xét SQLite khi cần lưu lịch sử dài hạn.

### ADR-009 · Thị trường hai mức chi tiết (Detailed / Aggregate) — `Đề xuất` (prototype mới có Detailed; Aggregate làm khi mở rộng >50 nước)
- **Hệ quả:** Hiển thị đủ quốc gia nhưng chỉ tốn CPU cho nơi có hoạt động.

### ADR-010 · Framework test tối giản tự viết thay cho gdUnit4 — `Đã chốt`
- **Bối cảnh:** gdUnit4/GUT là addon phụ thuộc phiên bản editor, cần bước cài đặt và dễ vỡ khi chạy headless trên CI.
- **Quyết định:** `tests/framework/test_case.gd` (assert cơ bản) + `tests/run_tests.gd` (tự tìm `test_*.gd`, trả mã thoát ≠ 0 khi lỗi). CI còn chặn thêm mọi `SCRIPT ERROR` trong log.
- **Hệ quả:** Không phụ thuộc bên ngoài; nếu cần mock/báo cáo JUnit có thể chuyển sang gdUnit4 sau mà không phải viết lại test (cùng kiểu hàm `test_*`).

### ADR-011 · Số thực trong save lưu dạng nhị phân base64 — `Đã chốt`
- **Bối cảnh:** Bộ đọc JSON của Godot 4.5 làm tròn sai ở chữ số cuối khi đọc lại số thực 17 chữ số → lưu/tải làm lệch mô phỏng.
- **Quyết định:** State có số thực (thị trường) mã hóa `PackedFloat64Array` → base64 (`SaveUtil.floats_to_b64`). Số nguyên vẫn là JSON thường.
- **Hệ quả:** Lưu/tải tất định tuyệt đối; phần thị trường trong file save không đọc được bằng mắt (phần còn lại vẫn là JSON).

### ADR-012 · Giá thị trường theo bộ điều khiển tỉ lệ trên mức tồn kho — `Đã chốt`
- **Bối cảnh:** Giá thay đổi theo tốc độ lệch tồn kho → dao động tăng dần (đo bằng `balance_runner`).
- **Quyết định:** giá mục tiêu = P_ref × (ngày tồn / mục tiêu)^(−độ nhạy), giá thực tiến dần về mục tiêu. Chi tiết: `docs/gdd/economy.md`.

### ADR-013 · UI dựng bằng code, co giãn `canvas_items` với khung thiết kế 1600×900 — `Đã chốt`
- **Lý do:** File `.tscn` viết tay dễ lỗi và khó review/merge; dựng bằng code giúp module tự đăng ký màn hình. Co giãn `canvas_items` + `expand` giữ bố cục không vỡ từ 1366×768 đến 4K.
- **Hệ quả:** Ít dùng editor kéo-thả cho UI; theme tập trung ở `src/ui/theme/app_theme.gd`.

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

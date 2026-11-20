# CLAUDE.md — Hướng dẫn cho Claude Code

Game: **World Economy: Build Your Empire** — mô phỏng kinh tế toàn cầu, Godot 4.x, GDScript.
Đọc trước khi làm: `docs/ARCHITECTURE.md` (kiến trúc), `docs/ROADMAP.md` (đang ở mốc nào), `docs/DECISIONS.md`.

## Luật kiến trúc (bắt buộc)

1. **Sim không biết UI.** Code trong `src/kernel/`, `src/core/`, `src/content/`, `src/modules/*/sim/` KHÔNG `extends Node`, KHÔNG dùng `get_tree()`, autoload, hay tham chiếu `ui/`. Chỉ `RefCounted`/`Resource`.
2. **Thay đổi state chỉ qua `SimCommand`** (từ người chơi/AI/kịch bản) hoặc bên trong `SimSystem.run()`. UI không bao giờ sửa state trực tiếp.
3. **UI chỉ đọc qua `Queries`**, ghi qua `GameSession.submit(command)`, nghe signal từ `SimBridge`.
4. **Module không sửa state của module khác** — dùng command/service/domain event của module đó.
5. **Phụ thuộc một chiều:** `core ← content ← kernel ← modules/*/sim ← persistence ← app ← ui`.
6. **Tiền không dùng float.** Dùng `Money`, `UnitPrice`, `Quantity` trong `src/core/types/`. Mọi phép tính tiền qua hàm của các kiểu này.
7. **Mọi bút toán tiền đi qua `Ledger.post()`** (sổ cái kép, Nợ = Có).
8. **Tất định:** không dùng `randf()`/`randi()` toàn cục hay thời gian thực trong sim; dùng `ctx.rng` (RngStream riêng từng system). Duyệt collection theo ID đã sắp xếp.
9. **Tham chiếu thực thể bằng ID chuỗi** (`co_000123`), không giữ object reference xuyên module.
10. **Nội dung là dữ liệu:** quốc gia/hàng hóa/công thức/sự kiện/AI profile nằm trong `data/base/*.json`, không hard-code.
11. **Đổi cấu trúc save → tăng `save_version` và viết migration** trong `src/persistence/migrations/`.

## Quy ước code

- Static typing bắt buộc cho biến, tham số, kiểu trả về.
- File/thư mục: `snake_case.gd`; `class_name` PascalCase; hằng số `UPPER_SNAKE`; ID nội dung `snake_case` (`crude_oil`), ID quốc gia ISO-3 (`VNM`).
- Module mới theo đúng khuôn: `<module>_module.gd` + `sim/{state,systems,commands,events,queries,serialization}` + `ui/`.
- Chuỗi hiển thị qua `tr("KEY")`, không hard-code tiếng Việt/Anh trong code.
- Comment/doc có thể viết tiếng Việt hoặc tiếng Anh, nhưng tên định danh bằng tiếng Anh.

## Quy trình

- Làm **một module/tính năng mỗi lần**. Không sửa nhiều module cùng lúc nếu chưa có test bao phủ.
- Logic kinh tế mới **phải có test** (`tests/unit/` mirror `src/`; chuỗi nghiệp vụ trong `tests/scenario/`).
- Trước khi commit: chạy test và validate data (lệnh bên dưới sẽ được cập nhật ở M0).
- Quyết định kiến trúc mới → thêm mục vào `docs/DECISIONS.md`.
- Xong việc của mốc → tick checklist trong `docs/ROADMAP.md`.

## Lệnh (cập nhật khi hoàn thành M0)

```bash
# Chạy toàn bộ test (gdUnit4, headless)
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/

# Kiểm tra dữ liệu JSON
godot --headless -s tools/validate_data.gd

# Kiểm tra phân lớp kiến trúc
godot --headless -s tools/lint_architecture.gd

# Chạy mô phỏng cân bằng N năm, xuất CSV
godot --headless -s tools/balance_runner.gd -- --years 10 --seed 42
```

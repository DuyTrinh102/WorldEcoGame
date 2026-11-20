# World Economy: Build Your Empire

Game mô phỏng kinh tế toàn cầu: người chơi xây dựng tập đoàn xuyên quốc gia thông qua tài nguyên, sản xuất, thương mại, logistics, tài chính và đầu tư.

- **Thể loại:** Business Simulation / Global Economy / Strategy
- **Nền tảng:** PC (Windows trước) · **Engine:** Godot 4.5 · GDScript
- **Trạng thái:** Prototype **v0.2 (M2)** — chơi được vòng lặp cốt lõi

## Chơi thử prototype

**Cách 1 — bản build Windows:** giải nén `WorldEconomy-Windows-prototype.zip`, chạy `WorldEconomy.exe`.
(Tự build: Actions → CI → *Run workflow* sẽ tạo artifact `WorldEconomy-windows`.)

**Cách 2 — từ source:** cài [Godot 4.5](https://godotengine.org/download) → *Import* thư mục này → nhấn **F5**.

### Điều khiển
| Phím | Chức năng |
|------|-----------|
| `Space` | Tạm dừng / chạy |
| `1` `2` `3` `4` | Tốc độ 1 / 2 / 5 / 10 ngày mỗi giây |
| `F5` / `F9` | Lưu nhanh / tải nhanh (tự lưu mỗi cuối tháng) |
| Nút `?` | Xem lại hướng dẫn |

### Bạn có thể làm gì trong prototype
- 8 nền kinh tế (Việt Nam, Brazil, Hoa Kỳ, Trung Quốc, Ấn Độ, Úc, Ả Rập Xê Út, Đức), 12 hàng hóa với cung–cầu–giá biến động mỗi ngày, thương mại quốc tế tự vận hành.
- Mở kho ở các nước, mua hàng (có trượt giá), vận chuyển đường biển (thời gian, cước, rủi ro trễ).
- Xây 4 loại nhà máy (rang xay cà phê, thép, thực phẩm, phân bón) với công thức nguyên liệu, công suất, chi phí cố định/biến đổi, khấu hao.
- Bán hàng ghi công nợ — tiền về sau 30 ngày; vay ngân hàng, thấu chi.
- Báo cáo tài chính đầy đủ từ sổ cái kép: bảng cân đối, kết quả kinh doanh theo tháng, nhật ký bút toán.
- **Mục tiêu:** nâng giá trị ròng từ $5M lên $10M.

## Phát triển

```bash
godot --headless --import                                   # lần đầu sau khi clone
godot --headless --path . -s res://tests/run_tests.gd       # 58 test
godot --headless --path . -s res://tools/validate_data.gd   # kiểm tra dữ liệu
godot --headless --path . -s res://tools/lint_architecture.gd
godot --headless --path . -s res://tools/balance_runner.gd -- --years=10
```

| Tài liệu | Nội dung |
|----------|----------|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Kiến trúc: phân lớp, module/plugin, dữ liệu, save, test |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Lộ trình M0–M6, trạng thái hiện tại, kế hoạch sau 1.0 |
| [`docs/DECISIONS.md`](docs/DECISIONS.md) | Quyết định kiến trúc (ADR) & thiết kế cần xác nhận |
| [`docs/gdd/economy.md`](docs/gdd/economy.md) | Mô hình kinh tế đang chạy (công thức, tham số) |
| [`CLAUDE.md`](CLAUDE.md) | Luật làm việc cho Claude Code |

### Cấu trúc nhanh
```
src/core        kiểu số fixed-point, ngày, RNG tất định
src/content     nạp & kiểm tra dữ liệu JSON (data/base)
src/kernel      Simulation, phase, system, command, modifier
src/modules/*   world · corporate · finance · market · inventory · logistics · production · trade
                (mỗi module: sim/ thuần logic + ui/ màn hình riêng)
src/persistence lưu/tải có version + migration
src/app         GameSession, SimBridge, bản dịch
src/ui          khung giao diện, bản đồ, theme, component
```

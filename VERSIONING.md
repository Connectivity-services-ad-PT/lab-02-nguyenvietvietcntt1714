# Chiến lược Quản lý Phiên bản (Versioning Strategy)

**Dự án:** Hệ thống dịch vụ AI phân tích hình ảnh (AI Vision Service)
**Cặp đàm phán:** Core Business (B6) / AI Vision (B4)
**Phiên bản Hợp đồng hiện tại:** v1.0.0

---

## 1. Tiêu chuẩn đánh phiên bản
Hệ thống API áp dụng tiêu chuẩn quốc tế **Semantic Versioning (SemVer)** với cấu trúc: `MAJOR.MINOR.PATCH` (Ví dụ: `1.0.0`).

* **MAJOR (Phiên bản chính - ví dụ: v2.0.0):** Tăng lên khi có thay đổi phá vỡ tính tương thích ngược (Breaking changes). 
  *Ví dụ:* Đổi tên đường dẫn từ `/vision/face-match` sang `/ai/face-match`, xóa trường `imageUrl` bắt buộc. Khi có bản MAJOR mới, Consumer (B6) bắt buộc phải sửa code để không bị lỗi.
* **MINOR (Phiên bản phụ - ví dụ: v1.1.0):** Tăng lên khi thêm tính năng mới nhưng vẫn tương thích ngược (Backward compatible). 
  *Ví dụ:* Thêm trường `age` (độ tuổi) và `gender` (giới tính) vào cục response trả về. Consumer nào chưa cần dùng thì hệ thống vẫn chạy bình thường, không gây sập lỗi.
* **PATCH (Bản vá - ví dụ: v1.0.1):** Tăng lên khi chỉ sửa lỗi (bug fixes) hiệu năng hoặc bảo mật ẩn bên trong server, không làm thay đổi cấu trúc dữ liệu JSON giao tiếp giữa 2 bên.

## 2. Vị trí đánh dấu phiên bản
* **Thiết kế Contract:** Phiên bản được ghi nhận tại trường `info.version` trong file `openapi.yaml`.
* **Giao tiếp thực tế:** Không chèn phiên bản cứng vào URL (như `/v1/vision/face-match`) để giữ URL sạch. Nếu sau này có nâng cấp bản MAJOR, sẽ sử dụng Header `Accept-Version` để định tuyến.

## 3. Vòng đời API (API Lifecycle)
* **Active (Đang hoạt động):** Phiên bản `v1.0.0` hiện tại đang được sử dụng làm chuẩn giao tiếp chính thức giữa B4 và B6.
* **Deprecated (Cảnh báo cũ):** Khi có phiên bản mới ra mắt (vd `v2.0.0`), bản `v1.0.0` sẽ chuyển sang trạng thái Deprecated. Provider (B4) cam kết vẫn duy trì bản cũ trong ít nhất 3 tháng và gửi thông báo để Consumer (B6) có thời gian nâng cấp.
* **Retired (Dừng hoạt động):** Sau thời hạn 3 tháng, phiên bản cũ sẽ bị tắt hoàn toàn. Các request gọi vào bản cũ sẽ nhận lỗi HTTP `410 Gone`.
# Phân tích yêu cầu — vai Consumer

- Cặp đàm phán: Core Business (B6) / AI Vision (B4)
- Product: B
- Consumer service: Core Business (B6)
- Provider service: AI Vision (B4)
- Người viết: Hồ Thị Ngọc Vi (Đại diện nhóm B6)
- Ngày: 20/05/2026

---

## 1. Resource Consumer cần nhận/gửi

| Resource | Consumer dùng để làm gì? | Field bắt buộc với Consumer | Field có thể tùy chọn |
|---|---|---|---|
| `FaceMatchRequest` | Gửi link ảnh cho AI xử lý | `imageUrl` | |
| `FaceMatchResponse` | Đọc điểm tin cậy để ra quyết định mở cổng | `confidence`, `detectionId` | `userId` |
| `DetectionResult` | Lấy dữ liệu cho báo cáo an ninh, log hệ thống | `detectionId`, `status` | `userId`, `confidence` |

---

## 2. API Consumer cần gọi

| Method | Path | Lúc nào gọi? | Kỳ vọng response |
|---|---|---|---|
| POST | `/vision/face-match` | Sau khi user quét mặt ở cổng và ảnh đã được upload lên storage | Thông tin định danh `userId` và `confidence` |
| GET | `/vision/detections/{detectionId}` | Khi có sự cố an ninh cần truy xuất lại lịch sử nhận diện | Chi tiết của phiên xử lý AI trước đó |

---

## 3. Error case Consumer cần xử lý

Tối thiểu 5 case.

| Status | Consumer hiểu là gì? | Consumer sẽ xử lý thế nào? |
|---:|---|---|
| 400 | Request sai schema (ảnh quá 4MB) | Báo lỗi về trạm kiểm soát, không mở cửa, log lỗi. |
| 401 | Thiếu token | Refresh/cấu hình lại token hệ thống nội bộ. |
| 403 | Không đủ quyền | Báo lỗi quyền truy cập API nội bộ. |
| 404 | Không tìm thấy lịch sử detectionId | Báo "Không có dữ liệu" trên trang Admin Dashboard. |
| 422 | Vi phạm rule (URL ảnh không tải được) | Hủy yêu cầu mở cửa, yêu cầu người dùng quét lại mặt. |
| 408 / Timeout | AI xử lý quá 3 giây | Fail-closed: Từ chối mở cửa để đảm bảo an ninh, hiện "Thử lại". |

---

## 4. Giả định bổ sung

- Giả định 1: Core Business có toàn quyền quyết định logic nghiệp vụ, AI chỉ là công cụ tính toán.
- Giả định 2: Provider (AI) cam kết `detectionId` sinh ra là UUID để không lộ thông tin số lượng request.
- Giả định 3: Hạ tầng mạng nội bộ giữa Core và AI ổn định, băng thông đủ lớn để tải ảnh nhanh.

---

## 5. Câu hỏi cho Provider

1. Provider muốn nhận ảnh dạng Base64 hay URL ảnh? Cái nào tối ưu cho Provider hơn?
2. Trong trường hợp không thể xác định được người trong ảnh, response sẽ trả về như thế nào?
3. Provider đảm bảo thời gian phản hồi (p99) là bao lâu để không gây tắc nghẽn cổng an ninh?

---

## 6. Rủi ro tích hợp

| Rủi ro | Tác động | Đề xuất xử lý |
|---|---|---|
| Provider đổi kiểu dữ liệu (vd `detectionId` từ UUID sang Int) | Consumer parse lỗi, hỏng DB lưu trữ | Chốt chặt type/format (UUID) trong contract. |
| Provider thiếu mã lỗi chuẩn | Consumer khó xử lý ngoại lệ tự động | Chuẩn hóa toàn bộ lỗi theo Problem Details RFC 7807. |
| Khó truy vết log chéo hệ thống | Gỡ lỗi mất nhiều thời gian | Áp dụng `X-Correlation-Id` cho toàn bộ request. |
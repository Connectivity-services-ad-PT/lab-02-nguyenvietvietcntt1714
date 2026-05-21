# Phân tích yêu cầu — vai Provider

- Cặp đàm phán: Core Business (B6) / AI Vision (B4)
- Product: B
- Provider service: AI Vision (B4)
- Consumer service: Core Business (B6)
- Người viết: Nguyễn Viết Việt (Đại diện nhóm B4)
- Ngày: 20/05/2026

---

## 1. Resource chính

| Resource | Mô tả | Thuộc tính bắt buộc | Thuộc tính tùy chọn |
|---|---|---|---|
| `FaceMatchRequest` | Payload đầu vào để nhận diện | `imageUrl`, `X-Correlation-Id` (header) | |
| `FaceMatchResponse` | Kết quả phân tích khuôn mặt | `detectionId`, `confidence` | `userId` (trả về nếu nhận diện thành công) |
| `DetectionResult` | Dữ liệu tra cứu lịch sử phân tích | `detectionId`, `status`, `confidence` | `userId` |

---

## 2. Action/API dự kiến

| Method | Path | Mục đích | Consumer gọi khi nào? |
|---|---|---|---|
| POST | `/vision/face-match` | Gửi ảnh để AI nhận diện khuôn mặt | Khi người dùng quẹt thẻ/quét mặt tại cổng an ninh |
| GET | `/vision/detections/{detectionId}` | Tra cứu lại kết quả phân tích theo ID | Khi Core cần đối soát, audit log hoặc debug lỗi |

---

## 3. Error case

Tối thiểu 5 case.

| Status | Tình huống | Response body dự kiến |
|---:|---|---|
| 400 | Payload sai định dạng (thiếu imageUrl) hoặc ảnh > 4MB | `Problem` |
| 401 | Thiếu Bearer token xác thực | `Problem` |
| 403 | Token hợp lệ nhưng không có quyền gọi dịch vụ AI | `Problem` |
| 404 | detectionId không tồn tại trong hệ thống lưu trữ | `Problem` |
| 422 | Dữ liệu đúng JSON nhưng URL ảnh không thể tải được | `Problem` |
| 500 | Lỗi server hoặc AI Model bị crash | `Problem` |

---

## 4. Giả định bổ sung

Ghi rõ những điểm user story chưa nói nhưng Provider cần giả định.

- Giả định 1: Consumer (Core) sẽ tự xử lý việc lưu trữ ảnh gốc (S3/MinIO) và đảm bảo `imageUrl` là public link hoặc pre-signed link có thể tải được.
- Giả định 2: Provider chỉ làm nhiệm vụ tính toán điểm tin cậy (confidence), Consumer tự quyết định ngưỡng (threshold) để ra lệnh mở cửa hay không.
- Giả định 3: Không có yêu cầu lưu trữ lịch sử nhận diện vĩnh viễn, Provider sẽ dọn dẹp các `detectionId` cũ sau 30 ngày để tiết kiệm database.

---

## 5. Câu hỏi cho Consumer

1. Định dạng ảnh gửi lên là gì (chỉ JPG/PNG hay cả WebP)? Kích thước tối đa cho phép là bao nhiêu?
2. Nếu model AI trả về confidence thấp, Consumer muốn nhận báo lỗi 422 hay vẫn nhận 200 kèm điểm confidence thấp?
3. Consumer có cần tracking ID xuyên suốt để debug trên hệ thống log tập trung không?

---

## 6. Rủi ro tích hợp

| Rủi ro | Tác động | Đề xuất xử lý |
|---|---|---|
| Tên field không thống nhất | Consumer parse lỗi | Chốt naming trong `openapi.yaml` (dùng camelCase chuẩn). |
| Payload (Ảnh) quá lớn | Tràn RAM, chậm response | Không truyền base64, chuyển sang truyền `imageUrl` và chốt limit 4MB. |
| AI xử lý chậm gây treo luồng | Consumer bị timeout | Chốt SLA phản hồi trong 3 giây, nếu quá hạn Consumer tự động fail-closed. |
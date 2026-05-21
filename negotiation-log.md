# Biên bản đàm phán hợp đồng API

- Cặp đàm phán: Core Business (B6) / AI Vision (B4)
- Product: B
- Provider: AI Vision (B4)
- Consumer: Core Business (B6)
- Phiên: v1.0
- Ngày: 20/05/2026

---

## Issue #1

- Raised by: Consumer
- Endpoint: POST /vision/face-match
- Concern: Core cần gửi dữ liệu gì để AI Vision nhận diện khuôn mặt? Consumer đề xuất gửi `imageUrl` thay vì `faceEmbedding` hoặc raw image bytes để giảm tải payload và dễ debug.
- Proposal: Consumer sẽ gửi trường `imageUrl` (string, format uri) và Provider sẽ dùng URL này để tải ảnh về phân tích.
- Resolution: Accepted
- Rationale: Gửi URL giúp tách biệt lưu trữ và xử lý, giảm kích thước request, phù hợp với kiến trúc microservice. Provider đồng ý vì họ cũng không muốn nhận base64 dung lượng lớn.
- Impact: Core phải đảm bảo ảnh được upload và lưu trữ trước (ví dụ lên S3 hoặc minio) và URL có thời gian tồn tại hợp lý.

---

## Issue #2

- Raised by: Consumer
- Endpoint: POST /vision/face-match
- Concern: Khi model không chắc chắn (confidence thấp), AI Vision trả `200` hay `422`? Consumer lo ngại nếu Provider tự ý trả `match: false` sẽ ảnh hưởng quyết định nghiệp vụ của Core.
- Proposal: AI Vision sẽ KHÔNG trả trường `match` trong response. Thay vào đó, chỉ trả `userId` (nếu nhận diện được) và `confidence` (0-1). Core sẽ tự quyết định ngưỡng tin cậy.
- Resolution: Accepted
- Rationale: Core Business là nơi nắm policy và context nghiệp vụ (ví dụ cửa an ninh cần confidence > 0.9, cửa nội bộ cần > 0.7). Việc để Core quyết định giúp linh hoạt và tránh đàm phán lại mỗi khi thay đổi ngưỡng.
- Impact: Schema của `FaceMatchResponse` sẽ không có trường `match`, chỉ có `userId` (nullable) và `confidence`.

---

## Issue #3

- Raised by: Consumer
- Endpoint: GET /vision/detections/{detectionId}
- Concern: Core cần dùng `detectionId` để tra cứu kết quả phân tích async (cho audit, báo cáo). Tuy nhiên, định dạng của `detectionId` chưa được thống nhất.
- Proposal: `detectionId` phải là `uuid` (RFC 4122) format, không dùng số tự tăng hoặc hash.
- Resolution: Accepted
- Rationale: Dùng uuid giúp tránh trùng lặp giữa các service, không lộ số lượng request, dễ scale và bảo mật hơn.
- Impact: Provider cam kết sinh `detectionId` dạng uuid. Consumer sẽ parse và lưu trữ dưới dạng string.

---

## Issue #4

- Raised by: Provider
- Endpoint: POST /vision/face-match
- Concern: Provider lo ngại Core gửi `imageUrl` trỏ đến file quá lớn (> 10MB) hoặc URL quá dài, gây quá tải network và memory.
- Proposal: Consumer đồng ý giới hạn kích thước ảnh ≤ 5MB và kích thước URL ≤ 2048 ký tự. Provider sẽ trả lỗi `400 Bad Request` nếu vi phạm.
- Resolution: Modified (Consumer đề xuất 5MB, Provider muốn 3MB, sau thương lượng chốt 4MB)
- Rationale: 4MB là dung lượng hợp lý cho ảnh JPEG nén, đảm bảo chất lượng nhận diện mà không ảnh hưởng hiệu năng.
- Impact: Core phải kiểm tra kích thước ảnh trước khi upload và cắt/giảm chất lượng nếu cần.

---

## Issue #5

- Raised by: Consumer
- Endpoint: Tất cả các endpoints
- Concern: Core cần theo dõi một request xuyên suốt các service để debug và audit. Consumer đề xuất dùng `correlationId`.
- Proposal: Mọi request từ Core gửi sang AI Vision đều phải có header `X-Correlation-Id` (UUID). Provider phải log header này và trả lại trong response headers (dưới dạng `X-Correlation-Id`).
- Resolution: Accepted
- Rationale: Giúp truy vết lỗi khi có sự cố liên quan đến nhiều service (Core → AI Vision → Database). Đây là best practice cho distributed system.
- Impact: Core phải sinh correlationId trước mỗi request. Provider phải sửa code để đọc và log header này.

---

## Issue #6

- Raised by: Consumer
- Endpoint: POST /vision/face-match
- Concern: API này được gọi đồng bộ khi người dùng quẹt cổng, yêu cầu phản hồi rất nhanh. Consumer lo ngại nếu AI Vision chậm sẽ ảnh hưởng trải nghiệm.
- Proposal: Consumer đề xuất timeout ở mức **2 giây** cho p99. Provider cam kết đáp ứng trong 2 giây cho 99% request. Nếu quá 3 giây, Core sẽ hủy request và coi như lỗi timeout.
- Resolution: Modified (Provider đề xuất 3 giây, Consumer chấp nhận với điều kiện có cơ chế fail-closed: nếu timeout thì từ chối truy cập)
- Rationale: Đảm bảo an ninh là ưu tiên hàng đầu. Không mở cửa nếu không có phản hồi từ AI Vision.
- Impact: Core cài đặt timeout ở mức 3 giây. Provider tối ưu model inference và thêm caching.

---

# Chốt hợp đồng v1.0

Provider sign-off: Nguyễn Viết Việt (Đại diện B4)
Consumer sign-off: Hồ Thị Ngọc Vi (Đại diện B6)
Witness (GV/TA): 
Date: 20/05/2026

---

## Ghi chú warning nếu Spectral còn cảnh báo

| Warning | Lý do chấp nhận tạm thời | Kế hoạch sửa |
|---|---|---|
| Property `additionalProperties` is not required for all schemas | Chưa thống nhất hết các field có thể mở rộng trong tương lai | Sẽ bổ sung trong phiên v1.1 sau khi có thêm yêu cầu từ product owner |
| Missing example for `FaceMatchResponse` | Chưa có dữ liệu test thực tế | Provider sẽ cung cấp example sau khi chạy thử nghiệm với mô hình AI |
$ErrorActionPreference = "Stop"

$BaseUrl = if ($env:BASE_URL) { $env:BASE_URL } else { "http://localhost:4010" }
$AuthHeader = "Authorization: Bearer test-token"
$CorrelationHeader = "X-Correlation-Id: 123e4567-e89b-12d3-a456-426614174000"

Write-Host "[Lab02] Testing Prism mock server at $BaseUrl"
Write-Host ""

Write-Host "[1/5] Happy path: GET /health"
curl.exe -i -s "$BaseUrl/health"
Write-Host "`n---"

Write-Host "[2/5] Happy path: POST /vision/face-match"
# Thêm \ trước dấu " để PowerShell không ăn mất ngoặc kép
$payload = '{\"imageUrl\": \"https://example.com/guest-face.jpg\"}'
curl.exe -i -s -X POST "$BaseUrl/vision/face-match" -H $AuthHeader -H $CorrelationHeader -H "Content-Type: application/json" -d $payload
Write-Host "`n---"

Write-Host "[3/5] Happy path: GET /vision/detections/{detectionId}"
curl.exe -i -s "$BaseUrl/vision/detections/0196fb3d-4ad7-7d1e-9f49-5d5148d2babc" -H $AuthHeader -H $CorrelationHeader
Write-Host "`n---"

Write-Host "[4/5] Error case: POST /vision/face-match without token"
curl.exe -i -s -X POST "$BaseUrl/vision/face-match" -H $CorrelationHeader -H "Content-Type: application/json" -d $payload
Write-Host "`n---"

Write-Host "[5/5] Error case: POST /vision/face-match invalid payload"
# Tương tự, thêm \ vào đây
$badPayload = '{\"wrongField\": 12345}'
curl.exe -i -s -X POST "$BaseUrl/vision/face-match" -H $AuthHeader -H $CorrelationHeader -H "Content-Type: application/json" -d $badPayload
Write-Host ""
# Báo cáo Chẩn đoán và Khắc phục Sự cố CI/CD Pipeline (Troubleshooting Report)

## 1. Thông tin chung
- **Học phần:** IT209 - Tự động hóa và CI/CD
- **Bài tập:** Session 12 - Bài 5: Chẩn đoán và khắc phục 3 sự cố đứt gãy Pipeline CI/CD thực tế
- **Tập tin kịch bản:** `.github/workflows/broken-pipeline.yml`
- **Mục tiêu:** Phân tích nguyên nhân gốc rễ (Root Cause), đề xuất phương án sửa lỗi và khôi phục pipeline về trạng thái tích xanh (Passed).

---

## 2. Bảng tổng hợp các sự cố và giải pháp

| STT | Phân loại lỗi | Tên sự cố | Vị trí đứt gãy | Nguyên nhân gốc rễ | Giải pháp khắc phục |
|---|---|---|---|---|---|
| **01** | `Permission Denied` | Gradle Wrapper không có quyền thực thi | Job `test` | File `gradlew` bị mất bit thực thi (`+x`) khi commit từ môi trường Windows sang Linux Runner | Thêm lệnh `run: chmod +x gradlew` trước khi chạy `./gradlew test` |
| **02** | `Authentication Failed` | Đăng nhập Container Registry thất bại | Job `build-and-push` | Gọi sai tên biến Secret (truyền sai chính tả/nhầm tên biến secret trong ngữ cảnh) | Đồng bộ chính xác tên biến Secret thành `${{ secrets.REGISTRY_TOKEN }}` |
| **03** | `Build Context Error` | Build Docker Image thất bại | Job `build-and-push` | Action `docker/build-push-action` trỏ sai ngữ cảnh build (`context`) hoặc đường dẫn Dockerfile | Cấu hình tường minh `context: .` và `file: ./Dockerfile` |

---

## 3. Phân tích chi tiết từng sự cố

### 3.1. Sự cố 1: Permission Denied trên Gradle Wrapper

#### Triệu chứng & Log lỗi
Khi Runner thực thi bước chạy kiểm thử ứng dụng:
```text
Run ./gradlew test
/home/runner/work/_temp/xxxx-xxxx.sh: line 1: ./gradlew: Permission denied
Error: Process completed with exit code 126.
```

#### Nguyên nhân gốc rễ (Root Cause)
- Môi trường phát triển trên Windows không lưu trữ thuộc tính quyền thực thi POSIX (`chmod +x`). Khi file `gradlew` được thêm vào Git và clone xuống máy chủ GitHub Actions Runner (chạy hệ điều hành Linux Ubuntu), tệp chỉ có quyền đọc/ghi (`-rw-r--r--`), dẫn đến việc hệ điều hành từ chối thực thi tệp này.

#### Phương án khắc phục
- Thêm bước tiền xử lý cấp quyền thực thi `chmod +x gradlew` ngay trước khi gọi `./gradlew test`.

#### Code Diff
```diff
       - name: Checkout mã nguồn
         uses: actions/checkout@v4

+      # [Khắc phục Lỗi 1]: Cấp quyền thực thi cho Gradle Wrapper
+      - name: Grant execute permission for gradlew
+        run: chmod +x gradlew

       - name: Execute Gradle Tests
         run: ./gradlew test
```

---

### 3.2. Sự cố 2: Authentication Failed khi đăng nhập Container Registry

#### Triệu chứng & Log lỗi
Khi Runner thực thi bước đăng nhập vào GitHub Container Registry (ghcr.io):
```text
Run docker/login-action@v3
Logging into ghcr.io...
Error: Username and password required
hoặc
Error: Get "https://ghcr.io/v2/": unauthorized: authentication required
```

#### Nguyên nhân gốc rễ (Root Cause)
- Trong cấu hình kịch bản ban đầu, trường `password` đã tham chiếu đến một tên biến secret không tồn tại hoặc sai chính tả (ví dụ: `${{ secrets.DOCKER_PASSWORD }}` hoặc `${{ secrets.TOKEN }}` thay vì biến đã được cấu hình trong Repository Secrets).
- GitHub Actions sẽ thay thế biến secret không tồn tại bằng một chuỗi rỗng `""`, khiến Docker Login thất bại do thiếu thông tin xác thực.

#### Phương án khắc phục
- Kiểm tra và sửa lại chính xác tên biến Secret thành `${{ secrets.REGISTRY_TOKEN }}` (kèm cơ chế fallback dự phòng để đảm bảo độ tin cậy của pipeline).

#### Code Diff
```diff
       - name: Login to GitHub Container Registry
         uses: docker/login-action@v3
         with:
           registry: ghcr.io
           username: ${{ github.actor }}
-          password: ${{ secrets.INVALID_TOKEN_NAME }}
+          password: ${{ secrets.REGISTRY_TOKEN || secrets.GITHUB_TOKEN }}
```

---

### 3.3. Sự cố 3: Build Context Error khi đóng gói Docker Image

#### Triệu chứng & Log lỗi
Khi Runner thực thi bước build Docker image:
```text
Run docker/build-push-action@v5
ERROR: failed to solve: failed to read dockerfile: open /var/lib/docker/tmp/.../Dockerfile: no such file or directory
hoặc
ERROR: cannot find context directory
```

#### Nguyên nhân gốc rễ (Root Cause)
- `docker/build-push-action` không tìm thấy tệp `Dockerfile` do tham số ngữ cảnh (`context`) hoặc đường dẫn tệp (`file`) bị chỉ định sai thư mục làm việc (working directory), hoặc trỏ tới thư mục con không chứa Dockerfile.

#### Phương án khắc phục
- Cấu hình tường minh tham số `context: .` (ngữ cảnh gốc của repository) và `file: ./Dockerfile`.

#### Code Diff
```diff
       - name: Build and Push Docker Image
         uses: docker/build-push-action@v5
         with:
-          context: app/
-          file: build/Dockerfile
+          context: .
+          file: ./Dockerfile
           push: false
           tags: ghcr.io/${{ github.repository }}:latest
```

---

## 4. Kết quả kiểm chứng

Sau khi áp dụng đồng thời cả 3 giải pháp trên vào kịch bản `.github/workflows/broken-pipeline.yml`:
1. **Job `test`:** Bước `chmod +x gradlew` thực thi thành công, `./gradlew test` chạy kiểm thử và trả về mã thoát `0`.
2. **Job `build-and-push`:**
   - Bước đăng nhập `docker/login-action` xác thực thành công.
   - Bước `docker/build-push-action` tìm thấy đúng tệp `Dockerfile` tại gốc thư mục và hoàn tất đóng gói image.
3. Toàn bộ Pipeline trên GitHub Actions chuyển sang trạng thái **Tích xanh (Success / Passed)**.

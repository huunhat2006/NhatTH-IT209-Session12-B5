# Bài 5: Chẩn đoán và khắc phục 3 sự cố đứt gãy Pipeline CI/CD thực tế

## 1. Giới thiệu
Thư mục này chứa mã nguồn và tài liệu hoàn thiện cho Bài tập 5 - Session 12 (IT209).

## 2. Các tệp tin trong dự án
- `.github/workflows/broken-pipeline.yml`: Kịch bản CI/CD đã được sửa đổi và khắc phục toàn bộ 3 lỗi đứt gãy.
- `troubleshooting.md`: Báo cáo chi tiết phân tích triệu chứng lỗi, nguyên nhân gốc rễ (Root Cause) và code diff khắc phục.
- `gradlew`: Script Gradle Wrapper phục vụ chạy kiểm thử trong môi trường CI.
- `Dockerfile`: Cấu hình Docker image hợp lệ với build context tại thư mục gốc.

## 3. Ba sự cố đã khắc phục
1. **Lỗi 1 (Permission Denied):** Thêm bước `run: chmod +x gradlew` trước khi gọi `./gradlew test`.
2. **Lỗi 2 (Authentication Failed):** Sửa đúng tên biến secret thành `${{ secrets.REGISTRY_TOKEN }}`.
3. **Lỗi 3 (Build Context Error):** Cấu hình `context: .` và `file: ./Dockerfile` trong bước `docker/build-push-action@v5`.

## 4. Sản phẩm nộp bài
- Tệp kịch bản `.github/workflows/broken-pipeline.yml` đã sửa.
- Tệp báo cáo `troubleshooting.md`.
- Ảnh chụp màn hình kết quả tích xanh trên tab GitHub Actions (`pipeline-success.png`).

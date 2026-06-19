# Lab: Secrets Management + Supply Chain Security + Platform Integration

Dự án này triển khai một mô hình thực hành tích hợp bảo mật chuỗi cung ứng ứng dụng (**Supply Chain Security**), quản lý mã bí mật (**Secrets Management**) và tích hợp nền tảng (**Platform Integration**) trên Kubernetes sử dụng GitOps.

## 1. Thành phần kiến trúc chính

### 1.1. Chuỗi cung ứng an toàn (Supply Chain Security)
Hệ thống xây dựng một pipeline CI/CD tự động bằng GitHub Actions đảm bảo tính toàn vẹn và an toàn cho mã nguồn và container image:
* **Build & Scan (Trivy):** Tự động build Docker image từ mã nguồn. Ngay sau đó, công cụ **Trivy** sẽ tiến hành quét lỗ hổng bảo mật (CVE). Nếu hình ảnh "sạch" lỗ hổng (hoặc thỏa mãn điều kiện an toàn), image mới được phép `push` lên **GitHub Container Registry (GHCR)**.
* **Ký ảnh số (Cosign):** Sử dụng **Cosign** để tạo cặp khóa (Private/Public key). 
  * `Private Key` được cấu hình an toàn trong **GitHub Secrets** để ký số vào image trong pipeline CI.
  * `Public Key` được commit vào repository và dán vào chính sách kiểm soát của cụm (`policies/cluster-image-policy.yaml` dưới tham số `authorities.key.data`) nhằm xác thực image khi deploy vào Kubernetes.

### 1.2. Quản lý mã bí mật (Secrets Management với ESO)
Thay vì lưu trữ trực tiếp các Kubernetes Secret thô (Base64) lên Git, lab này tích hợp nền tảng **External Secrets Operator (ESO)**:
* **Tự động hóa quay vòng khóa (Secret Rotation):** Cấu hình thuộc tính `refreshInterval` là `1m`, đảm bảo thời gian dài nhất để hệ thống nhận diện thay đổi và tự động cập nhật (rotate) secret là 60 giây.
* **Đảm bảo thứ tự triển khai (ArgoCD Sync Wave):** Để tránh lỗi phụ thuộc khi cài đặt qua mô hình GitOps, cấu hình thuộc tính `argocd.argoproj.io/sync-wave` được áp dụng chặt chẽ:
  * Khởi tạo thành phần ESO core: `sync-wave: "-1"`
  * Cấu hình kết nối hạ tầng (ESO Config/SecretStore): `sync-wave: "0"`

---

## 2. Kết quả triển khai thực tế

Dựa trên các cấu hình và minh chứng từ hệ thống:
1. **Pipeline CI/CD chạy thành công:** Hệ thống tự động kích hoạt workflow, kiểm tra lỗ hổng phần mềm, phê duyệt chất lượng hình ảnh và đẩy sản phẩm đóng gói lên registry an toàn.
2. **Đồng bộ ứng dụng hoàn tất:** Các tệp manifest cấu hình thứ tự cài đặt chính xác, các Secret được giải mã và map trực tiếp vào Pod của cluster Kubernetes thành công mà không làm lộ thông tin nhạy cảm trên Git Repository.
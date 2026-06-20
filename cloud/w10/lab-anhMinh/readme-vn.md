# Lab Thực Hành AWS Macie - Triển Khai bằng Terraform

Cấu hình Terraform này triển khai đầy đủ lab AWS Macie để phát hiện dữ liệu nhạy cảm trong các bucket Amazon S3 và gửi thông báo qua Amazon SNS.

## Tổng Quan Kiến Trúc

```
┌──────────────────────────────────────────────────────────────┐
│                    AWS Cloud                                   │
├──────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐                                               │
│  │  S3 Bucket  │──────┐                                        │
│  │ (chứa PII)  │      │                                        │
│  └─────────────┘      │                                        │
│                       │                                        │
│                       ▼                                        │
│              ┌──────────────────┐                              │
│              │ Amazon Macie Job │                              │
│              │  (Quét một lần)  │                              │
│              └──────────────────┘                              │
│                       │                                        │
│                       ▼ (Kết quả phát hiện)                    │
│              ┌──────────────────┐                              │
│              │  EventBridge     │                              │
│              │    Rule          │                              │
│              └──────────────────┘                              │
│                       │                                        │
│                       ▼                                        │
│              ┌──────────────────┐                              │
│              │   SNS Topic      │──────→ Email cho người dùng │
│              │  (Macie Alerts)  │                              │
│              └──────────────────┘                              │
│                                                                 │
└──────────────────────────────────────────────────────────────┘
```

## Yêu Cầu Tiên Quyết

1. **Tài khoản AWS**: Tài khoản AWS đang hoạt động với quyền phù hợp
2. **Terraform**: Phiên bản 1.0 trở lên đã được cài đặt
3. **AWS CLI**: Đã cấu hình với thông tin xác thực phù hợp (không bắt buộc nhưng nên có)
4. **Địa chỉ email**: Một địa chỉ email hợp lệ để nhận thông báo SNS

## Hướng Dẫn Cài Đặt

### Bước 1: Chuẩn Bị Các Biến Cấu Hình

1. Sao chép `terraform.tfvars.example` thành `terraform.tfvars`:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Chỉnh sửa `terraform.tfvars` và cập nhật các biến cần thiết:
   - Thay `your-email@example.com` bằng địa chỉ email thực của bạn
   - Cập nhật `aws_region` nếu cần (mặc định: ap-southeast-1)
   - Các biến khác có thể giữ nguyên giá trị mặc định

```hcl
email_address = "your-actual-email@example.com"
aws_region    = "ap-southeast-1"
```

### Bước 2: Khởi Tạo Terraform

Khởi tạo thư mục làm việc Terraform:

```bash
cd "Detect Sensitive data in Amazon S3 buckets and sent notifications using Amazon Macie"
terraform init
```

### Bước 3: Xem Lại Kế Hoạch

Trước khi áp dụng, hãy xem lại những tài nguyên sẽ được tạo:

```bash
terraform plan -out=tfplan
```

Lệnh này sẽ hiển thị:
- 1 S3 Bucket với mã hóa và chặn truy cập công khai
- 1 SNS Topic để gửi cảnh báo
- 1 đăng ký email cho SNS
- 1 công việc phân loại Macie (classification job)
- 1 quy tắc EventBridge để chuyển tiếp kết quả phát hiện của Macie đến SNS
- File dữ liệu mẫu chứa thông tin nhạy cảm

### Bước 4: Áp Dụng Cấu Hình

Áp dụng cấu hình Terraform để tạo tài nguyên:

```bash
terraform apply tfplan
```

**Quan trọng**: Sau khi áp dụng, bạn sẽ nhận được email từ AWS SNS yêu cầu xác nhận đăng ký. Bạn PHẢI nhấp vào liên kết xác nhận trong email đó để các cảnh báo có thể hoạt động.

### Bước 5: Xác Nhận Đăng Ký SNS

1. Kiểm tra hộp thư đến của bạn (kể cả thư mục spam)
2. Tìm email có tiêu đề: "AWS Notification - Subscription Confirmation"
3. Nhấp vào liên kết xác nhận trong email
4. Bạn sẽ thấy thông báo "Subscription confirmed!"

### Bước 6: Theo Dõi Quá Trình Thực Thi Macie Job

1. Đăng nhập vào AWS Management Console
2. Truy cập dịch vụ Amazon Macie
3. Vào mục Jobs
4. Job của bạn "S3-Sensitive-Data-Scan-Job" sẽ xuất hiện ở đó
5. Kiểm tra trạng thái (thường mất từ 5-30 phút tùy thuộc vào kích thước file)

### Bước 7: Xem Lại Kết Quả Phát Hiện

Sau khi Macie job hoàn tất:

1. Vào Amazon Macie → mục Findings
2. Bạn sẽ thấy các kết quả phát hiện liên quan đến dữ liệu nhạy cảm:
   - Số thẻ tín dụng (định dạng: Personal/CreditCardNumber)
   - Thông tin cá nhân nhận dạng được (PII)
   - Thông tin xác thực/API Keys
   - Địa chỉ email
   - Số điện thoại
   - Số ID

3. Kiểm tra email để xem thông báo SNS với chi tiết các phát hiện

## Tổng Quan Các File

| File | Mục đích |
|------|---------|
| `providers.tf` | Cấu hình provider AWS |
| `variables.tf` | Các biến đầu vào để tùy chỉnh |
| `s3.tf` | Thiết lập S3 bucket với mã hóa và tải lên dữ liệu mẫu |
| `sns.tf` | Topic SNS và đăng ký email |
| `macie.tf` | Kích hoạt tài khoản Macie và job phân loại |
| `eventbridge.tf` | Quy tắc EventBridge để chuyển tiếp kết quả phát hiện đến SNS |
| `outputs.tf` | Các giá trị đầu ra với thông tin quan trọng |
| `sample_data.txt` | File mẫu chứa dữ liệu nhạy cảm giả lập để kiểm thử |
| `terraform.tfvars.example` | File biến mẫu (sao chép thành terraform.tfvars) |
| `terraform.tfstate` | File trạng thái Terraform (được tạo tự động) |
| `README.md` | File này |

## Lưu Ý Quan Trọng

### Yêu Cầu Xác Nhận Email
- Đăng ký SNS sẽ KHÔNG hoạt động cho đến khi bạn xác nhận qua email
- Kiểm tra thư mục spam nếu bạn không thấy email trong vài phút
- Nếu email không đến, bạn có thể xác nhận thủ công từ AWS Console:
  - Vào SNS → Topics → Macie-Alerts-Topic → Subscriptions
  - Tìm đăng ký email của bạn với trạng thái "PendingConfirmation"
  - Nhấp vào nút "Confirm subscription"

### Dữ Liệu Nhạy Cảm Trong File Mẫu
File `sample_data.txt` chứa dữ liệu nhạy cảm thực tế nhưng HOÀN TOÀN GIẢ LẬP:
- Số thẻ tín dụng giả (4111 1111 1111 1111 là số thử nghiệm)
- Số ID giả
- API key và thông tin xác thực giả

**CẢNH BÁO**: KHÔNG sử dụng dữ liệu nhạy cảm thật trong lab này.

### Thời Gian Chạy Macie Job
- Công việc phân loại Macie có thể mất 5-30 phút để hoàn tất
- Thời gian phụ thuộc vào kích thước file và hàng đợi dịch vụ AWS
- Bạn có thể theo dõi tiến trình trong AWS Console

### Cân Nhắc Về Chi Phí
- Macie tính phí theo mỗi 1000 đối tượng được quét (thường rất thấp đối với lab nhỏ)
- Chi phí lưu trữ S3 không đáng kể đối với file nhỏ
- Thông báo SNS miễn phí cho 1000 email mỗi tháng
- Tổng chi phí ước tính cho lab này: < 1 USD

## Dọn Dẹp Và Hủy Tài Nguyên

Để xóa tất cả tài nguyên và tránh phát sinh chi phí:

```bash
# Trước khi hủy, bạn có thể muốn lưu lại các log
terraform destroy
```

Bạn sẽ được yêu cầu xác nhận. Gõ `yes` để tiếp tục.

Việc này sẽ xóa:
- ✓ S3 bucket và tất cả đối tượng bên trong
- ✓ SNS topic và các đăng ký
- ✓ Quy tắc EventBridge
- ✓ Macie classification job
- ✓ Tài khoản Macie (nếu bạn đặt enable_macie_job = false trong lần chạy cuối)

**Lưu ý dọn dẹp thủ công**: Nếu tài khoản Macie vẫn còn được bật trong AWS console, bạn có thể cần tắt thủ công từ phần cài đặt AWS Macie để tránh phát sinh chi phí.

## Xử Lý Sự Cố

### Sự cố: Không nhận được email xác nhận đăng ký
**Giải pháp**:
1. Kiểm tra thư mục spam/junk
2. Kiểm tra địa chỉ email trong `terraform.tfvars`
3. Xác nhận thủ công từ AWS Console (SNS → Subscriptions)

### Sự cố: Macie job không có kết quả phát hiện nào
**Nguyên nhân có thể**:
1. Job vẫn đang chạy (đợi thêm vài phút)
2. Macie có thể không phát hiện được mẫu dữ liệu nhạy cảm
3. Kiểm tra trạng thái Macie job trong AWS Console
4. Xác minh tên S3 bucket khớp với bucket đã được tạo

### Sự cố: Không nhận được thông báo SNS
**Nguyên nhân có thể**:
1. Đăng ký email chưa được xác nhận
2. Macie job chưa hoàn tất
3. Quy tắc EventBridge chưa được kết nối đúng cách với SNS
4. Kiểm tra AWS CloudWatch Logs để tìm lỗi của quy tắc EventBridge

### Sự cố: Terraform apply thất bại
**Giải pháp khả thi**:
1. Xác minh thông tin xác thực AWS đã được cấu hình đúng
2. Đảm bảo tài khoản AWS của bạn có quyền Macie
3. Kiểm tra biến `email_address` đã được thiết lập
4. Thử chạy lại `terraform init`

## Đầu Ra (Outputs)

Sau khi `terraform apply` thành công, bạn sẽ thấy các giá trị đầu ra bao gồm:
- Tên S3 bucket
- ARN của SNS topic
- Tên quy tắc EventBridge
- ID của Macie job
- Vị trí file dữ liệu mẫu
- Các bước tiếp theo quan trọng

Bạn có thể xem các đầu ra bất cứ lúc nào với:

```bash
terraform output
```

## Tài Liệu Tham Khảo Bổ Sung

- [Tài liệu AWS Macie](https://docs.aws.amazon.com/macie/)
- [Tài liệu Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Tài liệu AWS SNS](https://docs.aws.amazon.com/sns/)
- [Tài liệu AWS EventBridge](https://docs.aws.amazon.com/eventbridge/)

## Danh Sách Kiểm Tra Hoàn Thành Lab

- [ ] Đã sao chép các file Terraform và cấu hình biến
- [ ] `terraform init` hoàn tất thành công
- [ ] Đã xem lại `terraform plan`
- [ ] `terraform apply` hoàn tất
- [ ] Đã nhận và nhấp vào email xác nhận đăng ký
- [ ] Macie job đã hoàn tất (kiểm tra trong AWS Console)
- [ ] Kết quả phát hiện xuất hiện trong Macie console
- [ ] Đã nhận được thông báo email với chi tiết kết quả phát hiện
- [ ] Đã dọn dẹp tài nguyên bằng `terraform destroy`

## Hỗ Trợ

Nếu gặp vấn đề hoặc có câu hỏi:
1. Kiểm tra trạng thái dịch vụ trong AWS Console
2. Xem lại log Terraform: `TF_LOG=DEBUG terraform apply`
3. Kiểm tra AWS CloudWatch Logs để tìm lỗi thực thi EventBridge
4. Xác minh quyền IAM cho các thao tác Macie

---

**Cập nhật lần cuối**: 2026-06-19
**Thời lượng lab**: 30-45 phút
**Các dịch vụ AWS sử dụng**: S3, SNS, Macie, EventBridge, IAM

# Kubernetes Lab: RBAC & Admission Policy

## Overview
Trong lab này, tôi thực hành hai cơ chế bảo mật quan trọng của Kubernetes:

- **RBAC (Role-Based Access Control)**: quản lý quyền truy cập của người dùng.
- **Admission Policy (OPA Gatekeeper)**: kiểm soát và từ chối các tài nguyên không tuân thủ chính sách của hệ thống.

---

# 1. RBAC (Role-Based Access Control)

## Mục tiêu
Phân quyền cho các nhóm người dùng khác nhau trong cluster.

### Các vai trò được xây dựng

| Role | Quyền |
|--------|------|
| Developer | Deploy ứng dụng trong namespace `demo` |
| SRE | Xem toàn bộ cluster và thao tác Pod |
| Viewer | Chỉ đọc tài nguyên trong cluster |

---

## Developer Role

Developer chỉ được thao tác trên namespace `demo`.

Ví dụ kiểm tra quyền:

```bash
kubectl auth can-i create deploy -n demo --as alice
```

Kết quả:

```text
yes
```

Nếu deploy ở namespace khác:

```bash
kubectl auth can-i create deploy -n kube-system --as alice
```

Kết quả:

```text
no
```

---

## SRE Role

SRE có quyền:

- Xem toàn bộ tài nguyên trong cluster.
- Quản lý Pod phục vụ xử lý sự cố.

Ví dụ:

```bash
kubectl auth can-i get pods -A --as bob
```

Kết quả:

```text
yes
```

---

## Viewer Role

Viewer chỉ có quyền:

```yaml
verbs:
- get
- list
- watch
```

Không được chỉnh sửa tài nguyên.

Ví dụ:

```bash
kubectl auth can-i delete nodes --as carol
```

Kết quả:

```text
no
```

---

# 2. Admission Policy với OPA Gatekeeper

## Mục tiêu

Kiểm tra tài nguyên trước khi được tạo vào cluster nhằm đảm bảo tuân thủ các tiêu chuẩn bảo mật và vận hành.

Kiến trúc:

```text
kubectl apply
       ↓
API Server
       ↓
Gatekeeper Admission Controller
       ↓
Constraint Template
       ↓
Constraint
       ↓
Allow / Deny
```

---

## Constraint Templates

Sau khi cài đặt Gatekeeper, cluster có các ConstraintTemplate:

```bash
kubectl get constrainttemplates
```

Ví dụ:

```text
k8scontainerlimits
k8sdisallowedtags
k8spspallowedusers
k8spsphostnetworkports
```

Các template này định nghĩa logic kiểm tra cho các policy.

---

# Các chính sách đã triển khai

## 1. Không cho phép chạy container bằng root

Container phải khai báo:

```yaml
securityContext:
  runAsNonRoot: true
```

hoặc

```yaml
securityContext:
  runAsUser: 1000
```

---

## 2. Bắt buộc khai báo resource limits

Ví dụ:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

Giúp tránh việc container sử dụng quá nhiều tài nguyên của cluster.

---

## 3. Cấm sử dụng tag `latest`

Không cho phép:

```yaml
image: nginx:latest
```

Khuyến khích sử dụng:

```yaml
image: nginx:1.27.1
```

Việc cố định version giúp:

- Dễ rollback.
- Triển khai ổn định.
- Tránh thay đổi ngoài ý muốn.

---

## 4. Giới hạn số lượng replicas

Policy:

```yaml
maxReplicas: 5
```

Áp dụng cho:

```yaml
apiVersion: apps/v1
kind: Deployment
```

trong namespace:

```text
demo
```

Nếu Deployment khai báo:

```yaml
replicas: 10
```

thì sẽ bị Gatekeeper từ chối.

---

# Kiểm tra Policy

Tạo Pod vi phạm:

```bash
kubectl apply -f test-denied-pod.yaml
```

Gatekeeper phát hiện:

- Chạy bằng root.
- Không có resource limits.
- Sử dụng image tag `latest`.

Ví dụ cảnh báo:

```text
[disallow-root-user]
[require-container-limits]
[disallow-latest-tag]
```

---

# Kiến thức đạt được

Thông qua lab này, tôi hiểu được:

### RBAC

- Role
- ClusterRole
- RoleBinding
- ClusterRoleBinding
- Kiểm tra quyền bằng:

```bash
kubectl auth can-i
```

---

### Admission Policy

- ConstraintTemplate
- Constraint
- Admission Controller
- OPA Gatekeeper
- Thực thi policy trước khi tài nguyên được tạo

---

# Kết luận

RBAC và Admission Policy là hai lớp bảo mật quan trọng trong Kubernetes:

- **RBAC** quyết định *ai được phép làm gì*.
- **Admission Policy** quyết định *tài nguyên nào được phép tồn tại trong cluster*.

Việc kết hợp hai cơ chế này giúp tăng cường bảo mật, chuẩn hóa quy trình triển khai và hạn chế các cấu hình không mong muốn trong môi trường Kubernetes.
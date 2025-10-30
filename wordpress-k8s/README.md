# WordPress trên Kubernetes

## Cấu trúc thư mục
```
wordpress-k8s/
├── mysql/          - Các file cấu hình MySQL
├── wordpress/      - Các file cấu hình WordPress
├── ingress/        - Các file cấu hình Ingress và HTTPS
└── backup/         - Các file cấu hình backup và restore
```

## Hướng dẫn triển khai

### 1. Tạo namespace
```bash
kubectl apply -f mysql/01-namespace.yaml
```

### 2. Triển khai MySQL
```bash
kubectl apply -f mysql/02-secret.yaml
kubectl apply -f mysql/03-pv.yaml
kubectl apply -f mysql/04-pvc.yaml
kubectl apply -f mysql/05-deployment.yaml
kubectl apply -f mysql/06-service.yaml
```

### 3. Triển khai WordPress
```bash
kubectl apply -f wordpress/01-pv.yaml
kubectl apply -f wordpress/02-pvc.yaml
kubectl apply -f wordpress/03-deployment.yaml
kubectl apply -f wordpress/04-service.yaml
```

### 4. Cài đặt Ingress Controller
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/aws/deploy.yaml
```

### 5. Tạo TLS certificate
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=mmt157.io.vn/O=mmt157.io.vn"

kubectl create secret tls wordpress-tls \
  --cert=tls.crt --key=tls.key \
  -n wordpress
```

### 6. Triển khai Ingress
```bash
kubectl apply -f ingress/03-ingress.yaml
```

### 7. Triển khai Backup
```bash
kubectl apply -f backup/01-backup-cronjob.yaml
```

## Kiểm tra trạng thái
```bash
# Kiểm tra pods
kubectl get pods -n wordpress

# Kiểm tra services
kubectl get svc -n wordpress

# Kiểm tra ingress
kubectl get ingress -n wordpress

# Xem logs
kubectl logs -n wordpress -l app=wordpress
kubectl logs -n wordpress -l app=mysql
```

## Thông tin đăng nhập
- Database: wordpress
- User: wpuser
- Password: WpPassword123!
- Root Password: MyStrongPassword123!

## Lưu ý
- Cần thay thế <VOLUME_ID> trong các file PV bằng EBS Volume ID thực tế
- Cần cấu hình DNS trỏ mmt157.io.vn về Load Balancer của Ingress
- Backup sẽ chạy tự động mỗi ngày lúc 2h sáng

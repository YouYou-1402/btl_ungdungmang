#!/bin/bash

set -e

echo "=========================================="
echo "WordPress + MySQL Deployment on K3s"
echo "=========================================="
echo ""

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function để in màu
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Kiểm tra kubectl
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl không được cài đặt"
    exit 1
fi

print_success "kubectl đã được cài đặt"

# 1. Tạo namespace
print_info "Bước 1: Tạo namespace..."
kubectl apply -f mysql/01-namespace.yaml
print_success "Namespace đã được tạo"
echo ""

# 2. Tạo Secret
print_info "Bước 2: Tạo MySQL Secret..."
kubectl apply -f mysql/02-secret.yaml
print_success "Secret đã được tạo"
echo ""

# 3. Tạo TLS Certificate
print_info "Bước 3: Tạo TLS Certificate..."
cd ingress
chmod +x 01-tls-secret.sh
./01-tls-secret.sh
cd ..
print_success "TLS Certificate đã được tạo"
echo ""

# 4. Deploy MySQL
print_info "Bước 4: Deploy MySQL..."
kubectl apply -f mysql/03-pvc.yaml
print_info "Đợi PVC được bound..."
sleep 5
kubectl apply -f mysql/04-deployment.yaml
kubectl apply -f mysql/05-service.yaml
print_success "MySQL đã được deploy"
echo ""

# Đợi MySQL ready
print_info "Đợi MySQL khởi động..."
kubectl wait --for=condition=ready pod -l app=mysql -n wordpress --timeout=300s
print_success "MySQL đã sẵn sàng"
echo ""

# 5. Deploy WordPress
print_info "Bước 5: Deploy WordPress..."
kubectl apply -f wordpress/01-pvc.yaml
sleep 5
kubectl apply -f wordpress/02-deployment.yaml
kubectl apply -f wordpress/03-service.yaml
print_success "WordPress đã được deploy"
echo ""

# Đợi WordPress ready
print_info "Đợi WordPress khởi động..."
kubectl wait --for=condition=ready pod -l app=wordpress -n wordpress --timeout=300s
print_success "WordPress đã sẵn sàng"
echo ""

# 6. Deploy Ingress
print_info "Bước 6: Deploy Ingress..."
kubectl apply -f ingress/02-ingress.yaml
print_success "Ingress đã được tạo"
echo ""

# 7. Setup Backup
print_info "Bước 7: Setup Backup..."
kubectl apply -f backup/01-backup-pvc.yaml
kubectl apply -f backup/02-backup-cronjob.yaml
print_success "Backup CronJob đã được tạo"
echo ""

# Hiển thị thông tin
echo "=========================================="
echo "Deployment hoàn tất!"
echo "=========================================="
echo ""

echo "Thông tin triển khai:"
echo "-------------------"
echo "Namespace: wordpress"
echo "Domain: https://mmt157.io.vn"
echo ""

echo "Kiểm tra trạng thái:"
echo "-------------------"
kubectl get all,pvc,ingress -n wordpress
echo ""

echo "Lấy IP của Ingress Controller:"
echo "-------------------"
kubectl get svc -n kube-system traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
echo ""
echo ""

echo "Cấu hình DNS:"
echo "-------------------"
echo "Trỏ domain mmt157.io.vn về IP trên"
echo ""

echo "Truy cập WordPress:"
echo "-------------------"
echo "URL: https://mmt157.io.vn"
echo "⚠️  Chấp nhận cảnh báo certificate (self-signed)"
echo ""

echo "Xem logs:"
echo "-------------------"
echo "MySQL:     kubectl logs -f deployment/mysql -n wordpress"
echo "WordPress: kubectl logs -f deployment/wordpress -n wordpress"
echo ""

echo "Backup:"
echo "-------------------"
echo "Auto backup: Mỗi ngày lúc 2h sáng"
echo "Manual backup: kubectl create job --from=cronjob/mysql-backup mysql-backup-manual -n wordpress"
echo "List backups: kubectl exec -it deployment/mysql -n wordpress -- ls -lh /backup"
echo ""

print_success "Hoàn tất!"

#!/bin/bash

echo "=== Triển khai WordPress + MySQL trên Kubernetes ==="

# Tạo namespace ( khung chua tai nguyen)
echo "1. Tạo namespace..."
kubectl apply -f mysql/namespace.yaml

# Triển khai MySQL
echo "2. Triển khai MySQL..."
kubectl apply -f mysql/secret.yaml   #chua Mk & ttin DB
kubectl apply -f mysql/persistentvolume.yaml   #Tao o dia
kubectl apply -f mysql/persistentvolumeclaim.yaml  #Yeu cau muon o dia
kubectl apply -f mysql/deployment.yaml   #Tao Pod chay MySQL ( Lay MK tu secret, lay o dia tu pvc, Gắn vào container tại /var/lib/mysql)
kubectl apply -f mysql/service.yaml    #Cấp DNS nội bộ để WordPress truy cập

# Đợi MySQL sẵn sàng
echo "3. Đợi MySQL khởi động..."
kubectl wait --for=condition=ready pod -l app=mysql -n wordpress --timeout=300s
#MySQL phải trả lời liveness & readiness probe thành công → Pod ổn định.

# Triển khai WordPress
echo "4. Triển khai WordPress..."
kubectl apply -f wordpress/persistentvolume.yaml       #Ổ đĩa lưu dữ liệu WordPress (ảnh, cấu hình
kubectl apply -f wordpress/persistentvolumeclaim.yaml
kubectl apply -f wordpress/deployment.yaml   #Chạy WordPress Pod
kubectl apply -f wordpress/service.yaml   #Tạo địa chỉ nội bộ cho Pod truy cập từ Ingress

# Đợi WordPress sẵn sàng
echo "5. Đợi WordPress khởi động..."
kubectl wait --for=condition=ready pod -l app=wordpress -n wordpress --timeout=300s

#WordPress kết nối đến MySQL thông qua: mysql-service (ClusterIP) -> Pod MySQL -> Database thực


# Cài đặt cert-manager giúp k8s tự động cấp chứng chỉ SSL
echo "6. Cài đặt cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Đợi cert-manager sẵn sàng
echo "7. Đợi cert-manager khởi động..."
sleep 30
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s

# Triển khai Ingress #cho phép người dùng ngoài (browser) truy cập service trong cluster bằng domain và HTTPS.
echo "8. Triển khai Ingress và Certificate..."
kubectl apply -f ingress/cert-manager.yaml
sleep 10
kubectl apply -f ingress/ingress.yaml

# Triển khai Backup CronJob
echo "9. Triển khai Backup CronJob..."      #bảo tồn dữ liệu (database + file uploads) định kỳ để phục hồi khi mất
kubectl apply -f backup/backup-cronjob.yaml

# Tạo thư mục backup
echo "10. Tạo thư mục backup..."
minikube ssh "sudo mkdir -p /mnt/backup/mysql /mnt/backup/wordpress"

echo ""
echo "=== Triển khai hoàn tất! ==="
echo ""
echo "Thông tin truy cập:"
echo "-------------------"
MINIKUBE_IP=$(minikube ip)
echo "1. Thêm vào /etc/hosts:"
echo "   sudo echo '$MINIKUBE_IP wordpress.local' >> /etc/hosts"
echo ""
echo "2. Truy cập WordPress:"
echo "   http://wordpress.local"
echo "   https://wordpress.local (với self-signed certificate)"
echo ""
echo "3. Kiểm tra trạng thái:"
echo "   kubectl get all -n wordpress"
echo ""
echo "4. Xem logs:"
echo "   kubectl logs -f deployment/wordpress -n wordpress"
echo "   kubectl logs -f deployment/mysql -n wordpress"




#minikube start --driver=docker
#dùng để khởi động cụm Kubernetes cục bộ (local cluster) bằng Minikube, và chọn Docker làm “driver” (máy ảo nền) để chạy các node của Kubernetes.
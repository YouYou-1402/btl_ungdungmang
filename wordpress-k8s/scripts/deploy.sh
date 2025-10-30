#!/bin/bash

echo "=========================================="
echo "🚀 TRIỂN KHAI WORDPRESS K8S"
echo "=========================================="

# Tạo namespace
echo "📦 Tạo namespace..."
kubectl create namespace wordpress 2>/dev/null || echo "Namespace đã tồn tại"

# Deploy MySQL
echo "🗄️  Deploy MySQL..."
kubectl apply -f ../mysql/mysql-pv.yaml
kubectl apply -f ../mysql/mysql-pvc.yaml
kubectl apply -f ../mysql/mysql-secret.yaml
kubectl apply -f ../mysql/mysql-deployment.yaml
kubectl apply -f ../mysql/mysql-service.yaml

# Đợi MySQL sẵn sàng
echo "⏳ Đợi MySQL sẵn sàng..."
kubectl wait --for=condition=ready pod -l app=mysql -n wordpress --timeout=300s

# Deploy WordPress
echo "📝 Deploy WordPress..."
kubectl apply -f ../wordpress/wordpress-pv.yaml
kubectl apply -f ../wordpress/wordpress-pvc.yaml
kubectl apply -f ../wordpress/wordpress-deployment.yaml
kubectl apply -f ../wordpress/wordpress-service.yaml

# Đợi WordPress sẵn sàng
echo "⏳ Đợi WordPress sẵn sàng..."
kubectl wait --for=condition=ready pod -l app=wordpress -n wordpress --timeout=300s

# Deploy PHPMyAdmin
echo "🔧 Deploy PHPMyAdmin..."
kubectl apply -f ../phpmyadmin/phpmyadmin-deployment.yaml
kubectl apply -f ../phpmyadmin/phpmyadmin-service.yaml

# Đợi PHPMyAdmin sẵn sàng
echo "⏳ Đợi PHPMyAdmin sẵn sàng..."
kubectl wait --for=condition=ready pod -l app=phpmyadmin -n wordpress --timeout=300s

# Deploy Backup
echo "💾 Deploy Backup system..."
kubectl apply -f ../backup/backup-pv.yaml
kubectl apply -f ../backup/backup-pvc.yaml
kubectl apply -f ../backup/backup-cronjob.yaml

# Deploy Ingress
echo "🌐 Deploy Ingress..."
kubectl apply -f ../ingress/wordpress-ingress.yaml
kubectl apply -f ../ingress/phpmyadmin-ingress.yaml

echo ""
echo "✅ TRIỂN KHAI HOÀN TẤT!"
echo ""
echo "📊 Trạng thái:"
kubectl get pods -n wordpress
echo ""
kubectl get svc -n wordpress
echo ""
kubectl get ingress -n wordpress

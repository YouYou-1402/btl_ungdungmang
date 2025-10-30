#!/bin/bash

# Script triển khai WordPress trên Kubernetes

set -e

echo "=== Bắt đầu triển khai WordPress trên Kubernetes ==="

# 1. Tạo namespace
echo "1. Tạo namespace..."
kubectl apply -f mysql/01-namespace.yaml

# 2. Triển khai MySQL
echo "2. Triển khai MySQL..."
kubectl apply -f mysql/02-secret.yaml
kubectl apply -f mysql/04-pvc.yaml
kubectl apply -f mysql/05-deployment.yaml
kubectl apply -f mysql/06-service.yaml

# Đợi MySQL ready
echo "Đợi MySQL khởi động..."
kubectl wait --for=condition=ready pod -l app=mysql -n wordpress --timeout=300s

# 3. Triển khai WordPress
echo "3. Triển khai WordPress..."
kubectl apply -f wordpress/02-pvc.yaml
kubectl apply -f wordpress/03-deployment.yaml
kubectl apply -f wordpress/04-service.yaml

# Đợi WordPress ready
echo "Đợi WordPress khởi động..."
kubectl wait --for=condition=ready pod -l app=wordpress -n wordpress --timeout=300s

# 4. Triển khai Backup
echo "4. Triển khai Backup CronJob..."
kubectl apply -f backup/01-backup-cronjob.yaml

echo ""
echo "=== Triển khai hoàn tất ==="
echo ""
echo "Kiểm tra trạng thái:"
echo "  kubectl get pods -n wordpress"
echo "  kubectl get svc -n wordpress"
echo ""
echo "Lưu ý: Cần cài đặt Ingress Controller và cấu hình TLS riêng"

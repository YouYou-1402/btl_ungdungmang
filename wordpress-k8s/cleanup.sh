#!/bin/bash

echo "=========================================="
echo "Cleanup WordPress + MySQL"
echo "=========================================="
echo ""

read -p "Bạn có chắc muốn xóa tất cả? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Hủy bỏ."
    exit 0
fi

echo "Đang xóa..."

# Xóa Ingress
kubectl delete -f ingress/02-ingress.yaml --ignore-not-found=true

# Xóa WordPress
kubectl delete -f wordpress/ --ignore-not-found=true

# Xóa MySQL
kubectl delete -f mysql/04-deployment.yaml --ignore-not-found=true
kubectl delete -f mysql/05-service.yaml --ignore-not-found=true

# Xóa Backup
kubectl delete -f backup/ --ignore-not-found=true

# Xóa PVC (dữ liệu sẽ bị xóa)
read -p "Xóa PVC và dữ liệu? (yes/no): " delete_data
if [ "$delete_data" == "yes" ]; then
    kubectl delete pvc --all -n wordpress
    echo "✓ Đã xóa tất cả PVC"
fi

# Xóa Secret
kubectl delete secret wordpress-tls -n wordpress --ignore-not-found=true
kubectl delete -f mysql/02-secret.yaml --ignore-not-found=true

# Xóa Namespace
read -p "Xóa namespace wordpress? (yes/no): " delete_ns
if [ "$delete_ns" == "yes" ]; then
    kubectl delete namespace wordpress
    echo "✓ Đã xóa namespace"
fi

echo ""
echo "✓ Cleanup hoàn tất!"

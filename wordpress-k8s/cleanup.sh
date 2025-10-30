#!/bin/bash

# Script xóa toàn bộ WordPress deployment

echo "=== Cảnh báo: Script này sẽ xóa toàn bộ WordPress deployment ==="
read -p "Bạn có chắc chắn muốn tiếp tục? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Hủy bỏ."
    exit 0
fi

echo "Đang xóa resources..."

# Xóa theo thứ tự ngược lại
kubectl delete -f backup/01-backup-cronjob.yaml --ignore-not-found=true
kubectl delete -f ingress/03-ingress.yaml --ignore-not-found=true
kubectl delete -f wordpress/04-service.yaml --ignore-not-found=true
kubectl delete -f wordpress/03-deployment.yaml --ignore-not-found=true
kubectl delete -f wordpress/02-pvc.yaml --ignore-not-found=true
kubectl delete -f wordpress/01-pv.yaml --ignore-not-found=true
kubectl delete -f mysql/06-service.yaml --ignore-not-found=true
kubectl delete -f mysql/05-deployment.yaml --ignore-not-found=true
kubectl delete -f mysql/04-pvc.yaml --ignore-not-found=true
kubectl delete -f mysql/03-pv.yaml --ignore-not-found=true
kubectl delete -f mysql/02-secret.yaml --ignore-not-found=true

# Xóa namespace (sẽ xóa tất cả resources còn lại)
kubectl delete namespace wordpress --ignore-not-found=true

echo "=== Xóa hoàn tất ==="

#!/bin/bash
read -p "Bạn có chắc chắn muốn xóa không? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Đã hủy xóa"
    exit 0
fi

echo "Đang xóa namespace wordpress..."
kubectl delete namespace wordpress

echo "Đang xóa PersistentVolumes..."
kubectl delete pv mysql-pv wordpress-pv backup-pv

echo "Đã xóa toàn bộ dự án"

#!/bin/bash

echo "⚠️  CẢNH BÁO: Thao tác này sẽ ghi đè dữ liệu hiện tại!"
read -p "Bạn có chắc chắn muốn restore không? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Đã hủy restore"
    exit 0
fi

echo "🔄 Đang restore database..."
kubectl delete job wordpress-restore -n wordpress 2>/dev/null
kubectl apply -f ../backup/restore-job.yaml
echo "⏳ Đợi restore hoàn thành..."
kubectl wait --for=condition=complete --timeout=300s job/wordpress-restore -n wordpress
echo ""
echo "📋 Logs:"
kubectl logs -n wordpress job/wordpress-restore

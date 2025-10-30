#!/bin/bash

echo "🔄 Chạy backup thủ công..."
kubectl delete job wordpress-manual-backup -n wordpress 2>/dev/null
kubectl apply -f ../backup/manual-backup-job.yaml
echo "⏳ Đợi backup hoàn thành..."
kubectl wait --for=condition=complete --timeout=300s job/wordpress-manual-backup -n wordpress
echo ""
echo "📋 Logs:"
kubectl logs -n wordpress job/wordpress-manual-backup

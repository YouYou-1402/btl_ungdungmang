#!/bin/bash

echo "TRẠNG THÁI HỆ THỐNG"
echo ""
echo "Pods:"
kubectl get pods -n wordpress -o wide

echo ""
echo "Services:"
kubectl get svc -n wordpress

echo ""
echo "Ingress:"
kubectl get ingress -n wordpress

echo ""
echo "PVC:"
kubectl get pvc -n wordpress

echo ""
echo "PV:"
kubectl get pv | grep -E "NAME|mysql-pv|wordpress-pv|backup-pv"

echo ""
echo "CronJobs:"
kubectl get cronjob -n wordpress

echo ""
echo "Recent Backup Jobs:"
kubectl get jobs -n wordpress | grep backup

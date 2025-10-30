#!/bin/bash

echo "=========================================="
echo "📋 WORDPRESS LOGS"
echo "=========================================="
kubectl logs -n wordpress -l app=wordpress --tail=50

echo ""
echo "=========================================="
echo "📋 MYSQL LOGS"
echo "=========================================="
kubectl logs -n wordpress -l app=mysql --tail=50

echo ""
echo "=========================================="
echo "📋 PHPMYADMIN LOGS"
echo "=========================================="
kubectl logs -n wordpress -l app=phpmyadmin --tail=50

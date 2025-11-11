#!/bin/bash

echo "WORDPRESS LOGS"
kubectl logs -n wordpress -l app=wordpress --tail=50

echo ""
echo "MYSQL LOGS"
kubectl logs -n wordpress -l app=mysql --tail=50

echo ""
echo "PHPMYADMIN LOGS"
kubectl logs -n wordpress -l app=phpmyadmin --tail=50

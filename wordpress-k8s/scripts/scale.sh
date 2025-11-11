#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: ./scale.sh <number_of_replicas>"
    echo "Example: ./scale.sh 3"
    exit 1
fi

REPLICAS=$1

echo "Scaling WordPress to $REPLICAS replicas..."
kubectl scale deployment wordpress -n wordpress --replicas=$REPLICAS

echo "Đợi pods sẵn sàng..."
kubectl wait --for=condition=ready pod -l app=wordpress -n wordpress --timeout=300s

echo "Đã scale WordPress to $REPLICAS replicas"
kubectl get pods -n wordpress -l app=wordpress

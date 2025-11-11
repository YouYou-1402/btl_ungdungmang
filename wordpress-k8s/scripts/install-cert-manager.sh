#!/bin/bash
echo "INSTALLING CERT-MANAGER"
# Cài đặt cert-manager
echo "Installing cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

echo ""
echo "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s

echo ""
echo "Cert-manager installed successfully!"
echo ""

# Kiểm tra
echo "Checking cert-manager pods..."
kubectl get pods -n cert-manager


#!/bin/bash
# get-dns-info.sh

echo "=== DNS CONFIGURATION GUIDE ==="

# Lấy External IP
EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" = "null" ]; then
    echo "LoadBalancer External IP not available. Checking NodePort..."
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
    if [ -z "$NODE_IP" ]; then
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    fi
    HTTP_PORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
    HTTPS_PORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
    
    echo "Configuration for NodePort:"
    echo "Node IP: $NODE_IP"
    echo "HTTP Port: $HTTP_PORT"
    echo "HTTPS Port: $HTTPS_PORT"
    echo ""
    echo "DNS Configuration:"
    echo "Type: A"
    echo "Name: @"
    echo "Value: $NODE_IP"
    echo ""
    echo "⚠️  Make sure ports 80 and 443 are forwarded to $HTTP_PORT and $HTTPS_PORT"
else
    echo "Configuration for LoadBalancer:"
    echo "External IP: $EXTERNAL_IP"
    echo ""
    echo "DNS Configuration:"
    echo "Type: A"
    echo "Name: @"
    echo "Value: $EXTERNAL_IP"
    echo ""
    echo "Type: A"
    echo "Name: www"
    echo "Value: $EXTERNAL_IP"
fi

echo ""
echo "Domain: mmt157.io.vn"
echo "TTL: 300 (recommended)"
echo ""
echo "After DNS configuration, test with:"
echo "nslookup mmt157.io.vn"
echo "curl -I http://mmt157.io.vn"

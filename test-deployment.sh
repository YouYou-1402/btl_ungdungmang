#!/bin/bash

echo "🧪 Testing WordPress deployment..."

# Test 1: Kiểm tra Docker Compose
echo "1️⃣ Testing Docker Compose deployment..."
cd docker-compose
if docker-compose ps | grep -q "Up"; then
    echo "✅ Docker Compose: Running"
    curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200" && echo "✅ WordPress accessible" || echo "❌ WordPress not accessible"
else
    echo "❌ Docker Compose: Not running"
fi

# Test 2: Kiểm tra Kubernetes
echo "2️⃣ Testing Kubernetes deployment..."
cd ../kubernetes

# Kiểm tra pods
if kubectl get pods -n wordpress | grep -q "Running"; then
    echo "✅ Kubernetes pods: Running"
else
    echo "❌ Kubernetes pods: Not running"
fi

# Kiểm tra services
kubectl get svc -n wordpress

# Kiểm tra ingress
kubectl get ingress -n wordpress

# Test 3: Kiểm tra HTTPS
echo "3️⃣ Testing HTTPS access..."
if curl -k -s -o /dev/null -w "%{http_code}" https://wordpress.local | grep -q "200"; then
    echo "✅ HTTPS: Working"
else
    echo "❌ HTTPS: Not working"
fi

# Test 4: Kiểm tra certificate
echo "4️⃣ Testing SSL certificate..."
kubectl get certificate -n wordpress
kubectl describe certificate wordpress-tls -n wordpress | grep -A5 "Status:"

# Test 5: Kiểm tra backup
echo "5️⃣ Testing backup functionality..."
cd ../backup
if [ -f "mysql-backup.sh" ] && [ -f "wordpress-backup.sh" ]; then
    echo "✅ Backup scripts: Available"
    # Test backup (không chạy thực tế để tránh spam)
    echo "📝 Run './mysql-backup.sh' and './wordpress-backup.sh' to test"
else
    echo "❌ Backup scripts: Missing"
fi

echo "🏁 Testing completed!"

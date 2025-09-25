#!/bin/bash

echo "🚀 Deploying WordPress on Kubernetes..."

# Create namespace
echo "📁 Creating namespace..."
kubectl apply -f namespace.yaml

# Deploy secrets
echo "🔐 Creating secrets..."
kubectl apply -f secrets/

# Deploy MySQL
echo "🗄️ Deploying MySQL..."
kubectl apply -f mysql/

# Wait for MySQL to be ready
echo "⏳ Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n wordpress --timeout=300s

# Deploy WordPress
echo "🐘 Deploying WordPress PHP-FPM..."
kubectl apply -f wordpress/

# Deploy Nginx
echo "🌐 Deploying Nginx..."
kubectl apply -f nginx/

# Deploy Ingress
echo "🌍 Deploying Ingress..."
kubectl apply -f ingress/

# Wait for deployments
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available deployment --all -n wordpress --timeout=300s

echo "✅ Deployment completed!"
echo ""
echo "📊 Checking status..."
kubectl get all -n wordpress

echo ""
echo "🌐 Access WordPress at:"
echo "- Internal: http://$(kubectl get svc nginx-service -n wordpress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "- Domain: http://mmt157.io.vn"
echo ""
echo "🔍 Useful commands:"
echo "kubectl get pods -n wordpress"
echo "kubectl logs -f deployment/wordpress-php -n wordpress"
echo "kubectl logs -f deployment/mysql -n wordpress"
echo "kubectl logs -f deployment/nginx -n wordpress"

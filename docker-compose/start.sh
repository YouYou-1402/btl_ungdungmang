#!/bin/bash

echo "🚀 Starting WordPress + MySQL with Docker Compose..."

# Tạo network nếu chưa có
docker network create wordpress_network 2>/dev/null || true

# Khởi động services
docker-compose up -d

echo "⏳ Waiting for services to start..."
sleep 30

# Kiểm tra trạng thái
docker-compose ps

echo "✅ Services started successfully!"
echo "🌐 WordPress: http://localhost:8080"
echo "🗄️  phpMyAdmin: http://localhost:8081"
echo "📊 MySQL: localhost:3306"

# Kiểm tra logs
echo "📋 Recent logs:"
docker-compose logs --tail=10

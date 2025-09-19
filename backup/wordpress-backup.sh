#!/bin/bash

# Cấu hình
NAMESPACE="wordpress"
WORDPRESS_POD=$(kubectl get pods -n $NAMESPACE -l app=wordpress -o jsonpath='{.items[0].metadata.name}')
BACKUP_DIR="/tmp/wordpress-backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="wordpress_files_${DATE}.tar.gz"

# Tạo thư mục backup
mkdir -p $BACKUP_DIR

echo "📁 Starting WordPress files backup..."
echo "Pod: $WORDPRESS_POD"
echo "Backup file: $BACKUP_FILE"

# Backup WordPress files
kubectl exec -n $NAMESPACE $WORDPRESS_POD -- tar czf - \
  -C /var/www/html \
  wp-content/uploads \
  wp-content/themes \
  wp-content/plugins \
  wp-config.php \
  .htaccess 2>/dev/null | cat > $BACKUP_DIR/$BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "✅ WordPress files backup completed: $BACKUP_DIR/$BACKUP_FILE"
    
    # Keep only last 7 backups
    find $BACKUP_DIR -name "wordpress_files_*.tar.gz" -mtime +7 -delete
    echo "🧹 Old backups cleaned up"
else
    echo "❌ WordPress files backup failed!"
    exit 1
fi

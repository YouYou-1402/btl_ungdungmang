#!/bin/bash

# Cấu hình
NAMESPACE="wordpress"
MYSQL_POD=$(kubectl get pods -n $NAMESPACE -l app=mysql -o jsonpath='{.items[0].metadata.name}')
BACKUP_DIR="/tmp/wordpress-backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="mysql_backup_${DATE}.sql"

# Tạo thư mục backup
mkdir -p $BACKUP_DIR

echo "🗄️ Starting MySQL backup..."
echo "Pod: $MYSQL_POD"
echo "Backup file: $BACKUP_FILE"

# Backup database
kubectl exec -n $NAMESPACE $MYSQL_POD -- mysqldump \
  -u root -prootpassword123 \
  --single-transaction \
  --routines \
  --triggers \
  wordpress > $BACKUP_DIR/$BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "✅ MySQL backup completed: $BACKUP_DIR/$BACKUP_FILE"
    
    # Compress backup
    gzip $BACKUP_DIR/$BACKUP_FILE
    echo "🗜️ Backup compressed: $BACKUP_DIR/$BACKUP_FILE.gz"
    
    # Keep only last 7 backups
    find $BACKUP_DIR -name "mysql_backup_*.sql.gz" -mtime +7 -delete
    echo "🧹 Old backups cleaned up"
else
    echo "❌ MySQL backup failed!"
    exit 1
fi

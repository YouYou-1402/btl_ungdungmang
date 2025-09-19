#!/bin/bash

# Kiểm tra tham số
if [ $# -ne 2 ]; then
    echo "Usage: $0 <mysql_backup_file> <wordpress_backup_file>"
    echo "Example: $0 mysql_backup_20231213_140000.sql.gz wordpress_files_20231213_140000.tar.gz"
    exit 1
fi

MYSQL_BACKUP=$1
WORDPRESS_BACKUP=$2
NAMESPACE="wordpress"
BACKUP_DIR="/tmp/wordpress-backups"

# Kiểm tra files tồn tại
if [ ! -f "$BACKUP_DIR/$MYSQL_BACKUP" ]; then
    echo "❌ MySQL backup file not found: $BACKUP_DIR/$MYSQL_BACKUP"
    exit 1
fi

if [ ! -f "$BACKUP_DIR/$WORDPRESS_BACKUP" ]; then
    echo "❌ WordPress backup file not found: $BACKUP_DIR/$WORDPRESS_BACKUP"
    exit 1
fi

echo "🔄 Starting restore process..."

# Restore MySQL
echo "📊 Restoring MySQL database..."
MYSQL_POD=$(kubectl get pods -n $NAMESPACE -l app=mysql -o jsonpath='{.items[0].metadata.name}')

if [[ $MYSQL_BACKUP == *.gz ]]; then
    # Giải nén và restore
    gunzip -c $BACKUP_DIR/$MYSQL_BACKUP | kubectl exec -i -n $NAMESPACE $MYSQL_POD -- mysql -u root -prootpassword123 wordpress
else
    # Restore trực tiếp
    kubectl exec -i -n $NAMESPACE $MYSQL_POD -- mysql -u root -prootpassword123 wordpress < $BACKUP_DIR/$MYSQL_BACKUP
fi

if [ $? -eq 0 ]; then
    echo "✅ MySQL restore completed"
else
    echo "❌ MySQL restore failed!"
    exit 1
fi

# Restore WordPress files
echo "📁 Restoring WordPress files..."
WORDPRESS_POD=$(kubectl get pods -n $NAMESPACE -l app=wordpress -o jsonpath='{.items[0].metadata.name}')

kubectl exec -i -n $NAMESPACE $WORDPRESS_POD -- tar xzf - -C /var/www/html < $BACKUP_DIR/$WORDPRESS_BACKUP

if [ $? -eq 0 ]; then
    echo "✅ WordPress files restore completed"
else
    echo "❌ WordPress files restore failed!"
    exit 1
fi

# Restart WordPress pod để áp dụng thay đổi
echo "🔄 Restarting WordPress pod..."
kubectl delete pod -n $NAMESPACE -l app=wordpress
kubectl wait --for=condition=ready pod -l app=wordpress -n $NAMESPACE --timeout=300s

echo "✅ Restore process completed successfully!"

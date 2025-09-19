#!/bin/bash

echo "🚀 Starting full WordPress backup..."

# Chạy MySQL backup
./mysql-backup.sh

# Chạy WordPress files backup  
./wordpress-backup.sh

echo "✅ Full backup completed!"
echo "📊 Backup summary:"
ls -lh /tmp/wordpress-backups/ | tail -10

#!/bin/bash

# ============================================
# SCRIPT TẠO CẤU TRÚC DỰ ÁN CHO GITHUB
# ============================================

set -e

echo "=========================================="
echo "📁 TẠO CẤU TRÚC DỰ ÁN WORDPRESS K8S"
echo "=========================================="

# Màu sắc
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# ============================================
# TẠO CẤU TRÚC THƯ MỤC
# ============================================
PROJECT_DIR="wordpress-k8s"

print_info "Tạo cấu trúc thư mục..."
mkdir -p $PROJECT_DIR/{mysql,wordpress,phpmyadmin,backup,ingress,scripts}
cd $PROJECT_DIR

# ============================================
# MYSQL FILES
# ============================================
print_info "Tạo MySQL files..."

cat > mysql/mysql-pv.yaml <<'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  hostPath:
    path: /mnt/data/mysql
    type: DirectoryOrCreate
EOF

cat > mysql/mysql-pvc.yaml <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
  namespace: wordpress
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  resources:
    requests:
      storage: 5Gi
EOF

cat > mysql/mysql-secret.yaml <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
  namespace: wordpress
type: Opaque
stringData:
  MYSQL_ROOT_PASSWORD: rootpassword123
  MYSQL_DATABASE: wordpress
  MYSQL_USER: wordpress
  MYSQL_PASSWORD: wordpress123
EOF

cat > mysql/mysql-deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
          name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_ROOT_PASSWORD
        - name: MYSQL_DATABASE
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_DATABASE
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_USER
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_PASSWORD
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-pvc
EOF

cat > mysql/mysql-service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: wordpress
spec:
  type: ClusterIP
  ports:
  - port: 3306
    targetPort: 3306
    protocol: TCP
  selector:
    app: mysql
EOF

# ============================================
# WORDPRESS FILES
# ============================================
print_info "Tạo WordPress files..."

cat > wordpress/wordpress-pv.yaml <<'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: wordpress-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  hostPath:
    path: /mnt/data/wordpress
    type: DirectoryOrCreate
EOF

cat > wordpress/wordpress-pvc.yaml <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wordpress-pvc
  namespace: wordpress
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  resources:
    requests:
      storage: 5Gi
EOF

cat > wordpress/wordpress-deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  namespace: wordpress
spec:
  replicas: 2
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
      - name: wordpress
        image: wordpress:latest
        ports:
        - containerPort: 80
          name: wordpress
        env:
        - name: WORDPRESS_DB_HOST
          value: mysql.wordpress.svc.cluster.local
        - name: WORDPRESS_DB_NAME
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_DATABASE
        - name: WORDPRESS_DB_USER
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_USER
        - name: WORDPRESS_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_PASSWORD
        volumeMounts:
        - name: wordpress-storage
          mountPath: /var/www/html
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 60
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 5
      volumes:
      - name: wordpress-storage
        persistentVolumeClaim:
          claimName: wordpress-pvc
EOF

cat > wordpress/wordpress-service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: wordpress
  namespace: wordpress
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
    protocol: TCP
  selector:
    app: wordpress
EOF

# ============================================
# PHPMYADMIN FILES
# ============================================
print_info "Tạo PHPMyAdmin files..."

cat > phpmyadmin/phpmyadmin-deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: phpmyadmin
  namespace: wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: phpmyadmin
  template:
    metadata:
      labels:
        app: phpmyadmin
    spec:
      containers:
      - name: phpmyadmin
        image: phpmyadmin:latest
        ports:
        - containerPort: 80
          name: phpmyadmin
        env:
        - name: PMA_HOST
          value: mysql.wordpress.svc.cluster.local
        - name: PMA_PORT
          value: "3306"
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_ROOT_PASSWORD
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
EOF

cat > phpmyadmin/phpmyadmin-service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: phpmyadmin
  namespace: wordpress
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30081
    protocol: TCP
  selector:
    app: phpmyadmin
EOF

# ============================================
# BACKUP FILES
# ============================================
print_info "Tạo Backup files..."

cat > backup/backup-pv.yaml <<'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: backup-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  hostPath:
    path: /mnt/data/backup
    type: DirectoryOrCreate
EOF

cat > backup/backup-pvc.yaml <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-pvc
  namespace: wordpress
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: local-storage
  resources:
    requests:
      storage: 10Gi
EOF

cat > backup/backup-cronjob.yaml <<'EOF'
apiVersion: batch/v1
kind: CronJob
metadata:
  name: wordpress-backup
  namespace: wordpress
spec:
  schedule: "0 2 * * *"  # Chạy lúc 2h sáng hàng ngày
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: mysql:8.0
            command:
            - /bin/bash
            - -c
            - |
              BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
              BACKUP_FILE="/backup/wordpress_backup_${BACKUP_DATE}.sql"
              
              echo "🔄 Bắt đầu backup database..."
              mysqldump -h mysql.wordpress.svc.cluster.local \
                        -u root \
                        -p${MYSQL_ROOT_PASSWORD} \
                        --all-databases \
                        --single-transaction \
                        --quick \
                        --lock-tables=false \
                        > ${BACKUP_FILE}
              
              if [ $? -eq 0 ]; then
                echo "✅ Backup thành công: ${BACKUP_FILE}"
                gzip ${BACKUP_FILE}
                echo "✅ Đã nén file backup"
                
                # Xóa backup cũ hơn 7 ngày
                find /backup -name "wordpress_backup_*.sql.gz" -mtime +7 -delete
                echo "✅ Đã xóa backup cũ hơn 7 ngày"
              else
                echo "❌ Backup thất bại!"
                exit 1
              fi
            env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-secret
                  key: MYSQL_ROOT_PASSWORD
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          restartPolicy: OnFailure
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
EOF

cat > backup/manual-backup-job.yaml <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: wordpress-manual-backup
  namespace: wordpress
spec:
  template:
    spec:
      containers:
      - name: backup
        image: mysql:8.0
        command:
        - /bin/bash
        - -c
        - |
          BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
          BACKUP_FILE="/backup/wordpress_manual_backup_${BACKUP_DATE}.sql"
          
          echo "🔄 Bắt đầu backup thủ công..."
          mysqldump -h mysql.wordpress.svc.cluster.local \
                    -u root \
                    -p${MYSQL_ROOT_PASSWORD} \
                    --all-databases \
                    --single-transaction \
                    --quick \
                    --lock-tables=false \
                    > ${BACKUP_FILE}
          
          if [ $? -eq 0 ]; then
            echo "✅ Backup thành công: ${BACKUP_FILE}"
            gzip ${BACKUP_FILE}
            echo "✅ Đã nén file backup"
            ls -lh /backup/
          else
            echo "❌ Backup thất bại!"
            exit 1
          fi
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_ROOT_PASSWORD
        volumeMounts:
        - name: backup-storage
          mountPath: /backup
      restartPolicy: Never
      volumes:
      - name: backup-storage
        persistentVolumeClaim:
          claimName: backup-pvc
  backoffLimit: 3
EOF

cat > backup/restore-job.yaml <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: wordpress-restore
  namespace: wordpress
spec:
  template:
    spec:
      containers:
      - name: restore
        image: mysql:8.0
        command:
        - /bin/bash
        - -c
        - |
          echo "📋 Danh sách file backup:"
          ls -lh /backup/
          
          # Lấy file backup mới nhất
          LATEST_BACKUP=$(ls -t /backup/wordpress_backup_*.sql.gz 2>/dev/null | head -1)
          
          if [ -z "$LATEST_BACKUP" ]; then
            echo "❌ Không tìm thấy file backup!"
            exit 1
          fi
          
          echo "🔄 Đang restore từ: $LATEST_BACKUP"
          
          gunzip -c $LATEST_BACKUP | mysql -h mysql.wordpress.svc.cluster.local \
                                            -u root \
                                            -p${MYSQL_ROOT_PASSWORD}
          
          if [ $? -eq 0 ]; then
            echo "✅ Restore thành công!"
          else
            echo "❌ Restore thất bại!"
            exit 1
          fi
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_ROOT_PASSWORD
        volumeMounts:
        - name: backup-storage
          mountPath: /backup
      restartPolicy: Never
      volumes:
      - name: backup-storage
        persistentVolumeClaim:
          claimName: backup-pvc
  backoffLimit: 3
EOF

# ============================================
# INGRESS FILES
# ============================================
print_info "Tạo Ingress files..."

cat > ingress/wordpress-ingress.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wordpress-ingress
  namespace: wordpress
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  ingressClassName: traefik
  rules:
  - host: mmt157.io.vn
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: wordpress
            port:
              number: 80
EOF

cat > ingress/phpmyadmin-ingress.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: phpmyadmin-ingress
  namespace: wordpress
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  ingressClassName: traefik
  rules:
  - host: pma.mmt157.io.vn
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: phpmyadmin
            port:
              number: 80
EOF

# ============================================
# SCRIPTS
# ============================================
print_info "Tạo management scripts..."

cat > scripts/deploy.sh <<'EOF'
#!/bin/bash

echo "=========================================="
echo "🚀 TRIỂN KHAI WORDPRESS K8S"
echo "=========================================="

# Tạo namespace
echo "📦 Tạo namespace..."
kubectl create namespace wordpress 2>/dev/null || echo "Namespace đã tồn tại"

# Deploy MySQL
echo "🗄️  Deploy MySQL..."
kubectl apply -f ../mysql/mysql-pv.yaml
kubectl apply -f ../mysql/mysql-pvc.yaml
kubectl apply -f ../mysql/mysql-secret.yaml
kubectl apply -f ../mysql/mysql-deployment.yaml
kubectl apply -f ../mysql/mysql-service.yaml

# Đợi MySQL sẵn sàng
echo "⏳ Đợi MySQL sẵn sàng..."
kubectl wait --for=condition=ready pod -l app=mysql -n wordpress --timeout=300s

# Deploy WordPress
echo "📝 Deploy WordPress..."
kubectl apply -f ../wordpress/wordpress-pv.yaml
kubectl apply -f ../wordpress/wordpress-pvc.yaml
kubectl apply -f ../wordpress/wordpress-deployment.yaml
kubectl apply -f ../wordpress/wordpress-service.yaml

# Đợi WordPress sẵn sàng
echo "⏳ Đợi WordPress sẵn sàng..."
kubectl wait --for=condition=ready pod -l app=wordpress -n wordpress --timeout=300s

# Deploy PHPMyAdmin
echo "🔧 Deploy PHPMyAdmin..."
kubectl apply -f ../phpmyadmin/phpmyadmin-deployment.yaml
kubectl apply -f ../phpmyadmin/phpmyadmin-service.yaml

# Đợi PHPMyAdmin sẵn sàng
echo "⏳ Đợi PHPMyAdmin sẵn sàng..."
kubectl wait --for=condition=ready pod -l app=phpmyadmin -n wordpress --timeout=300s

# Deploy Backup
echo "💾 Deploy Backup system..."
kubectl apply -f ../backup/backup-pv.yaml
kubectl apply -f ../backup/backup-pvc.yaml
kubectl apply -f ../backup/backup-cronjob.yaml

# Deploy Ingress
echo "🌐 Deploy Ingress..."
kubectl apply -f ../ingress/wordpress-ingress.yaml
kubectl apply -f ../ingress/phpmyadmin-ingress.yaml

echo ""
echo "✅ TRIỂN KHAI HOÀN TẤT!"
echo ""
echo "📊 Trạng thái:"
kubectl get pods -n wordpress
echo ""
kubectl get svc -n wordpress
echo ""
kubectl get ingress -n wordpress
EOF

cat > scripts/check-status.sh <<'EOF'
#!/bin/bash

echo "=========================================="
echo "📊 TRẠNG THÁI HỆ THỐNG"
echo "=========================================="

echo ""
echo "🔹 Pods:"
kubectl get pods -n wordpress -o wide

echo ""
echo "🔹 Services:"
kubectl get svc -n wordpress

echo ""
echo "🔹 Ingress:"
kubectl get ingress -n wordpress

echo ""
echo "🔹 PVC:"
kubectl get pvc -n wordpress

echo ""
echo "🔹 PV:"
kubectl get pv | grep -E "NAME|mysql-pv|wordpress-pv|backup-pv"

echo ""
echo "🔹 CronJobs:"
kubectl get cronjob -n wordpress

echo ""
echo "🔹 Recent Backup Jobs:"
kubectl get jobs -n wordpress | grep backup
EOF

cat > scripts/view-logs.sh <<'EOF'
#!/bin/bash

echo "=========================================="
echo "📋 WORDPRESS LOGS"
echo "=========================================="
kubectl logs -n wordpress -l app=wordpress --tail=50

echo ""
echo "=========================================="
echo "📋 MYSQL LOGS"
echo "=========================================="
kubectl logs -n wordpress -l app=mysql --tail=50

echo ""
echo "=========================================="
echo "📋 PHPMYADMIN LOGS"
echo "=========================================="
kubectl logs -n wordpress -l app=phpmyadmin --tail=50
EOF

cat > scripts/backup.sh <<'EOF'
#!/bin/bash

echo "🔄 Chạy backup thủ công..."
kubectl delete job wordpress-manual-backup -n wordpress 2>/dev/null
kubectl apply -f ../backup/manual-backup-job.yaml
echo "⏳ Đợi backup hoàn thành..."
kubectl wait --for=condition=complete --timeout=300s job/wordpress-manual-backup -n wordpress
echo ""
echo "📋 Logs:"
kubectl logs -n wordpress job/wordpress-manual-backup
EOF

cat > scripts/restore.sh <<'EOF'
#!/bin/bash

echo "⚠️  CẢNH BÁO: Thao tác này sẽ ghi đè dữ liệu hiện tại!"
read -p "Bạn có chắc chắn muốn restore không? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Đã hủy restore"
    exit 0
fi

echo "🔄 Đang restore database..."
kubectl delete job wordpress-restore -n wordpress 2>/dev/null
kubectl apply -f ../backup/restore-job.yaml
echo "⏳ Đợi restore hoàn thành..."
kubectl wait --for=condition=complete --timeout=300s job/wordpress-restore -n wordpress
echo ""
echo "📋 Logs:"
kubectl logs -n wordpress job/wordpress-restore
EOF

cat > scripts/scale.sh <<'EOF'
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./scale.sh <number_of_replicas>"
    echo "Example: ./scale.sh 3"
    exit 1
fi

REPLICAS=$1

echo "🔄 Scaling WordPress to $REPLICAS replicas..."
kubectl scale deployment wordpress -n wordpress --replicas=$REPLICAS

echo "⏳ Đợi pods sẵn sàng..."
kubectl wait --for=condition=ready pod -l app=wordpress -n wordpress --timeout=300s

echo "✅ Đã scale WordPress to $REPLICAS replicas"
kubectl get pods -n wordpress -l app=wordpress
EOF

cat > scripts/delete-all.sh <<'EOF'
#!/bin/bash

echo "⚠️  CẢNH BÁO: Thao tác này sẽ xóa toàn bộ dự án!"
read -p "Bạn có chắc chắn muốn xóa không? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Đã hủy xóa"
    exit 0
fi

echo "🗑️  Đang xóa namespace wordpress..."
kubectl delete namespace wordpress

echo "🗑️  Đang xóa PersistentVolumes..."
kubectl delete pv mysql-pv wordpress-pv backup-pv

echo "✅ Đã xóa toàn bộ dự án"
EOF

chmod +x scripts/*.sh


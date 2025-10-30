#!/bin/bash

# Script tạo cấu trúc thư mục và các file YAML cho WordPress trên Kubernetes

# Màu sắc cho output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Bắt đầu tạo cấu trúc thư mục WordPress K8s ===${NC}"

# Tạo thư mục gốc
mkdir -p wordpress-k8s
cd wordpress-k8s

# Tạo cấu trúc thư mục
echo -e "${GREEN}Tạo cấu trúc thư mục...${NC}"
mkdir -p mysql wordpress ingress backup

# ============================================
# MYSQL FILES
# ============================================
echo -e "${GREEN}Tạo file MySQL...${NC}"

# mysql/01-namespace.yaml
cat > mysql/01-namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: wordpress
EOF

# mysql/02-secret.yaml
cat > mysql/02-secret.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
  namespace: wordpress
type: Opaque
data:
  # root password: MyStrongPassword123!
  mysql-root-password: TXlTdHJvbmdQYXNzd29yZDEyMyE=
  # database: wordpress
  mysql-database: d29yZHByZXNz
  # user: wpuser
  mysql-user: d3B1c2Vy
  # password: WpPassword123!
  mysql-password: V3BQYXNzd29yZDEyMyE=
EOF

# mysql/03-pv.yaml
cat > mysql/03-pv.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
  namespace: wordpress
spec:
  capacity:
    storage: 20Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: gp2
  awsElasticBlockStore:
    volumeID: <VOLUME_ID>  # Sẽ tạo sau
    fsType: ext4
EOF

# mysql/04-pvc.yaml
cat > mysql/04-pvc.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
  namespace: wordpress
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp2
  resources:
    requests:
      storage: 20Gi
EOF

# mysql/05-deployment.yaml
cat > mysql/05-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: wordpress
  labels:
    app: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  strategy:
    type: Recreate
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
              key: mysql-root-password
        - name: MYSQL_DATABASE
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-database
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-user
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-password
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        livenessProbe:
          exec:
            command:
            - mysqladmin
            - ping
            - -h
            - localhost
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          exec:
            command:
            - mysqladmin
            - ping
            - -h
            - localhost
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 1
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-pvc
EOF

# mysql/06-service.yaml
cat > mysql/06-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: wordpress
  labels:
    app: mysql
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
echo -e "${GREEN}Tạo file WordPress...${NC}"

# wordpress/01-pv.yaml
cat > wordpress/01-pv.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: wordpress-pv
  namespace: wordpress
spec:
  capacity:
    storage: 20Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: gp2
  awsElasticBlockStore:
    volumeID: <VOLUME_ID>  # Sẽ tạo sau
    fsType: ext4
EOF

# wordpress/02-pvc.yaml
cat > wordpress/02-pvc.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wordpress-pvc
  namespace: wordpress
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp2
  resources:
    requests:
      storage: 20Gi
EOF

# wordpress/03-deployment.yaml
cat > wordpress/03-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  namespace: wordpress
  labels:
    app: wordpress
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
        image: wordpress:6.4-apache
        ports:
        - containerPort: 80
          name: wordpress
        env:
        - name: WORDPRESS_DB_HOST
          value: mysql:3306
        - name: WORDPRESS_DB_NAME
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-database
        - name: WORDPRESS_DB_USER
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-user
        - name: WORDPRESS_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-password
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
          timeoutSeconds: 5
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 5
          timeoutSeconds: 3
      volumes:
      - name: wordpress-storage
        persistentVolumeClaim:
          claimName: wordpress-pvc
EOF

# wordpress/04-service.yaml
cat > wordpress/04-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: wordpress
  namespace: wordpress
  labels:
    app: wordpress
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  selector:
    app: wordpress
EOF

# ============================================
# INGRESS FILES
# ============================================
echo -e "${GREEN}Tạo file Ingress...${NC}"

# ingress/01-ingress-nginx-controller.yaml
cat > ingress/01-ingress-nginx-controller.yaml << 'EOF'
# Cài đặt NGINX Ingress Controller
# Chạy lệnh sau thay vì file này:
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/aws/deploy.yaml
EOF

# ingress/02-tls-secret.yaml
cat > ingress/02-tls-secret.yaml << 'EOF'
# File này sẽ được tạo bằng lệnh sau khi đã có cert và key
# Tạo self-signed certificate trước
EOF

# ingress/03-ingress.yaml
cat > ingress/03-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wordpress-ingress
  namespace: wordpress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - mmt157.io.vn
    secretName: wordpress-tls
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

# ============================================
# BACKUP FILES
# ============================================
echo -e "${GREEN}Tạo file Backup...${NC}"

# backup/01-backup-cronjob.yaml
cat > backup/01-backup-cronjob.yaml << 'EOF'
apiVersion: batch/v1
kind: CronJob
metadata:
  name: mysql-backup
  namespace: wordpress
spec:
  # Chạy backup mỗi ngày lúc 2h sáng
  schedule: "0 2 * * *"
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: mysql-backup
            image: mysql:8.0
            env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-secret
                  key: mysql-root-password
            - name: MYSQL_DATABASE
              valueFrom:
                secretKeyRef:
                  name: mysql-secret
                  key: mysql-database
            command:
            - /bin/sh
            - -c
            - |
              BACKUP_FILE="/backup/wordpress-$(date +%Y%m%d-%H%M%S).sql"
              mysqldump -h mysql -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} > ${BACKUP_FILE}
              echo "Backup completed: ${BACKUP_FILE}"
              # Giữ lại 7 backup gần nhất
              ls -t /backup/*.sql | tail -n +8 | xargs -r rm
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          restartPolicy: OnFailure
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-pvc
  namespace: wordpress
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp2
  resources:
    requests:
      storage: 50Gi
EOF

# backup/02-restore-job.yaml
cat > backup/02-restore-job.yaml << 'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: mysql-restore
  namespace: wordpress
spec:
  template:
    spec:
      containers:
      - name: mysql-restore
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-root-password
        - name: MYSQL_DATABASE
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-database
        - name: BACKUP_FILE
          value: "wordpress-20240101-020000.sql"  # Thay đổi tên file cần restore
        command:
        - /bin/sh
        - -c
        - |
          if [ -f "/backup/${BACKUP_FILE}" ]; then
            mysql -h mysql -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} < /backup/${BACKUP_FILE}
            echo "Restore completed from: ${BACKUP_FILE}"
          else
            echo "Backup file not found: ${BACKUP_FILE}"
            exit 1
          fi
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
# TẠO FILE README
# ============================================
echo -e "${GREEN}Tạo file README.md...${NC}"

cat > README.md << 'EOF'
# WordPress trên Kubernetes

## Cấu trúc thư mục
```
wordpress-k8s/
├── mysql/          - Các file cấu hình MySQL
├── wordpress/      - Các file cấu hình WordPress
├── ingress/        - Các file cấu hình Ingress và HTTPS
└── backup/         - Các file cấu hình backup và restore
```

## Hướng dẫn triển khai

### 1. Tạo namespace
```bash
kubectl apply -f mysql/01-namespace.yaml
```

### 2. Triển khai MySQL
```bash
kubectl apply -f mysql/02-secret.yaml
kubectl apply -f mysql/03-pv.yaml
kubectl apply -f mysql/04-pvc.yaml
kubectl apply -f mysql/05-deployment.yaml
kubectl apply -f mysql/06-service.yaml
```

### 3. Triển khai WordPress
```bash
kubectl apply -f wordpress/01-pv.yaml
kubectl apply -f wordpress/02-pvc.yaml
kubectl apply -f wordpress/03-deployment.yaml
kubectl apply -f wordpress/04-service.yaml
```

### 4. Cài đặt Ingress Controller
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/aws/deploy.yaml
```

### 5. Tạo TLS certificate
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=mmt157.io.vn/O=mmt157.io.vn"

kubectl create secret tls wordpress-tls \
  --cert=tls.crt --key=tls.key \
  -n wordpress
```

### 6. Triển khai Ingress
```bash
kubectl apply -f ingress/03-ingress.yaml
```

### 7. Triển khai Backup
```bash
kubectl apply -f backup/01-backup-cronjob.yaml
```

## Kiểm tra trạng thái
```bash
# Kiểm tra pods
kubectl get pods -n wordpress

# Kiểm tra services
kubectl get svc -n wordpress

# Kiểm tra ingress
kubectl get ingress -n wordpress

# Xem logs
kubectl logs -n wordpress -l app=wordpress
kubectl logs -n wordpress -l app=mysql
```

## Thông tin đăng nhập
- Database: wordpress
- User: wpuser
- Password: WpPassword123!
- Root Password: MyStrongPassword123!

## Lưu ý
- Cần thay thế <VOLUME_ID> trong các file PV bằng EBS Volume ID thực tế
- Cần cấu hình DNS trỏ mmt157.io.vn về Load Balancer của Ingress
- Backup sẽ chạy tự động mỗi ngày lúc 2h sáng
EOF

# ============================================
# TẠO FILE DEPLOY SCRIPT
# ============================================
echo -e "${GREEN}Tạo file deploy.sh...${NC}"

cat > deploy.sh << 'EOF'
#!/bin/bash

# Script triển khai WordPress trên Kubernetes

set -e

echo "=== Bắt đầu triển khai WordPress trên Kubernetes ==="

# 1. Tạo namespace
echo "1. Tạo namespace..."
kubectl apply -f mysql/01-namespace.yaml

# 2. Triển khai MySQL
echo "2. Triển khai MySQL..."
kubectl apply -f mysql/02-secret.yaml
kubectl apply -f mysql/04-pvc.yaml
kubectl apply -f mysql/05-deployment.yaml
kubectl apply -f mysql/06-service.yaml

# Đợi MySQL ready
echo "Đợi MySQL khởi động..."
kubectl wait --for=condition=ready pod -l app=mysql -n wordpress --timeout=300s

# 3. Triển khai WordPress
echo "3. Triển khai WordPress..."
kubectl apply -f wordpress/02-pvc.yaml
kubectl apply -f wordpress/03-deployment.yaml
kubectl apply -f wordpress/04-service.yaml

# Đợi WordPress ready
echo "Đợi WordPress khởi động..."
kubectl wait --for=condition=ready pod -l app=wordpress -n wordpress --timeout=300s

# 4. Triển khai Backup
echo "4. Triển khai Backup CronJob..."
kubectl apply -f backup/01-backup-cronjob.yaml

echo ""
echo "=== Triển khai hoàn tất ==="
echo ""
echo "Kiểm tra trạng thái:"
echo "  kubectl get pods -n wordpress"
echo "  kubectl get svc -n wordpress"
echo ""
echo "Lưu ý: Cần cài đặt Ingress Controller và cấu hình TLS riêng"
EOF

chmod +x deploy.sh

# ============================================
# TẠO FILE CLEANUP SCRIPT
# ============================================
echo -e "${GREEN}Tạo file cleanup.sh...${NC}"

cat > cleanup.sh << 'EOF'
#!/bin/bash

# Script xóa toàn bộ WordPress deployment

echo "=== Cảnh báo: Script này sẽ xóa toàn bộ WordPress deployment ==="
read -p "Bạn có chắc chắn muốn tiếp tục? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Hủy bỏ."
    exit 0
fi

echo "Đang xóa resources..."

# Xóa theo thứ tự ngược lại
kubectl delete -f backup/01-backup-cronjob.yaml --ignore-not-found=true
kubectl delete -f ingress/03-ingress.yaml --ignore-not-found=true
kubectl delete -f wordpress/04-service.yaml --ignore-not-found=true
kubectl delete -f wordpress/03-deployment.yaml --ignore-not-found=true
kubectl delete -f wordpress/02-pvc.yaml --ignore-not-found=true
kubectl delete -f wordpress/01-pv.yaml --ignore-not-found=true
kubectl delete -f mysql/06-service.yaml --ignore-not-found=true
kubectl delete -f mysql/05-deployment.yaml --ignore-not-found=true
kubectl delete -f mysql/04-pvc.yaml --ignore-not-found=true
kubectl delete -f mysql/03-pv.yaml --ignore-not-found=true
kubectl delete -f mysql/02-secret.yaml --ignore-not-found=true

# Xóa namespace (sẽ xóa tất cả resources còn lại)
kubectl delete namespace wordpress --ignore-not-found=true

echo "=== Xóa hoàn tất ==="
EOF

chmod +x cleanup.sh

# ============================================
# HIỂN thị cấu trúc
# ============================================
echo ""
echo -e "${BLUE}=== Hoàn thành! ===${NC}"
echo ""
echo "Cấu trúc thư mục đã được tạo:"
tree -L 2 2>/dev/null || find . -type f -o -type d | sed 's|[^/]*/| |g'

echo ""
echo -e "${GREEN}Các file đã được tạo thành công!${NC}"
echo ""
echo "Để triển khai WordPress, chạy:"
echo "  cd wordpress-k8s"
echo "  ./deploy.sh"
echo ""
echo "Để xóa toàn bộ deployment, chạy:"
echo "  ./cleanup.sh"
echo ""
echo "Xem hướng dẫn chi tiết trong file README.md"

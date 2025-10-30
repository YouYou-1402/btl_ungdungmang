#!/bin/bash

# Script tạo self-signed certificate cho mmt157.io.vn

echo "Tạo self-signed certificate cho mmt157.io.vn..."

# Tạo private key
openssl genrsa -out tls.key 2048

# Tạo certificate signing request
openssl req -new -key tls.key -out tls.csr -subj "/C=VN/ST=Hanoi/L=Hanoi/O=MMT157/OU=IT/CN=mmt157.io.vn"

# Tạo certificate (valid 365 ngày)
openssl x509 -req -days 365 -in tls.csr -signkey tls.key -out tls.crt

# Tạo Kubernetes Secret
kubectl create namespace wordpress --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret tls wordpress-tls \
  --cert=tls.crt \
  --key=tls.key \
  -n wordpress \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✓ TLS Secret đã được tạo: wordpress-tls"
echo "✓ Certificate sẽ hết hạn sau 365 ngày"

# Xem thông tin certificate
echo ""
echo "Thông tin certificate:"
openssl x509 -in tls.crt -text -noout | grep -A 2 "Subject:"
openssl x509 -in tls.crt -text -noout | grep -A 2 "Validity"

# Cleanup
rm -f tls.csr

echo ""
echo "Files được tạo:"
echo "  - tls.key (private key)"
echo "  - tls.crt (certificate)"
echo ""
echo "Để xem secret trong cluster:"
echo "  kubectl get secret wordpress-tls -n wordpress"

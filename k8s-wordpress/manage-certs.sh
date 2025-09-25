#!/bin/bash

case $1 in
    "status")
        echo "📊 Certificate Status:"
        kubectl get certificates -n wordpress
        echo ""
        kubectl get secrets -n wordpress | grep tls
        ;;
    "describe")
        echo "📝 Certificate Details:"
        kubectl describe certificates -n wordpress
        ;;
    "switch-staging")
        echo "🔄 Switching to Let's Encrypt Staging..."
        kubectl patch ingress wordpress-ingress-letsencrypt -n wordpress -p '{"metadata":{"annotations":{"cert-manager.io/cluster-issuer":"letsencrypt-staging"}}}'
        kubectl patch ingress wordpress-ingress-letsencrypt -n wordpress -p '{"spec":{"tls":[{"hosts":["mmt157.io.vn"],"secretName":"wordpress-staging-tls"}]}}'
        ;;
    "switch-prod")
        echo "🚀 Switching to Let's Encrypt Production..."
        kubectl patch ingress wordpress-ingress-letsencrypt -n wordpress -p '{"metadata":{"annotations":{"cert-manager.io/cluster-issuer":"letsencrypt-prod"}}}'
        kubectl patch ingress wordpress-ingress-letsencrypt -n wordpress -p '{"spec":{"tls":[{"hosts":["mmt157.io.vn"],"secretName":"wordpress-prod-tls"}]}}'
        ;;
    "use-selfsigned")
        echo "🔐 Using Self-signed Certificate..."
        kubectl delete ingress wordpress-ingress-letsencrypt -n wordpress --ignore-not-found=true
        kubectl apply -f ingress/wordpress-ingress-multi-ssl.yaml
        ;;
    "use-letsencrypt")
        echo "🌍 Using Let's Encrypt Certificate..."
        kubectl delete ingress wordpress-ingress-selfsigned -n wordpress --ignore-not-found=true
        kubectl apply -f ingress/wordpress-ingress-multi-ssl.yaml
        ;;
    "renew")
        echo "🔄 Renewing certificates..."
        kubectl delete certificates --all -n wordpress
        kubectl apply -f ssl/wordpress-certificates.yaml
        ;;
    "clean")
        echo "🧹 Cleaning up certificates..."
        kubectl delete certificates --all -n wordpress
        kubectl delete secrets -l type=kubernetes.io/tls -n wordpress
        ;;
    *)
        echo "🔧 Certificate Management Commands:"
        echo "  status          - Show certificate status"
        echo "  describe        - Show detailed certificate info"
        echo "  switch-staging  - Switch to Let's Encrypt staging"
        echo "  switch-prod     - Switch to Let's Encrypt production"
        echo "  use-selfsigned  - Use self-signed certificates"
        echo "  use-letsencrypt - Use Let's Encrypt certificates"
        echo "  renew          - Renew all certificates"
        echo "  clean          - Clean up all certificates"
        ;;
esac

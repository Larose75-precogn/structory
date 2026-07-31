#!/bin/bash

# Script de déploiement PreCogn sur nginx (VPS OVH)
# Usage: ./deploy_nginx.sh

set -e

PROJECT_DIR="/home/ubuntu/projects/structory"
GODOT="/tmp/godot"
EXPORT_DIR="$PROJECT_DIR/export/web"
WEB_ROOT="/var/www/precogn"

echo "=========================================="
echo "  Déploiement PreCogn sur nginx"
echo "=========================================="
echo ""

# 1. Exporter le projet
echo "1. Export du projet Godot..."
cd "$PROJECT_DIR"
rm -rf "$EXPORT_DIR"/*
$GODOT --headless --export-release "Web" 2>&1 | tail -5

if [ ! -f "$EXPORT_DIR/index.html" ]; then
    echo "   ❌ Export échoué"
    exit 1
fi
echo "   ✓ Export réussi"
echo ""

# 2. Copier les fichiers
echo "2. Copie vers $WEB_ROOT..."
sudo mkdir -p "$WEB_ROOT"
sudo cp -r "$EXPORT_DIR"/* "$WEB_ROOT/"
sudo chown -R www-data:www-data "$WEB_ROOT"
echo "   ✓ Fichiers copiés"
echo ""

# 3. Vérifier nginx
echo "3. Vérification de nginx..."
sudo nginx -t
if [ $? -ne 0 ]; then
    echo "   ❌ Configuration nginx invalide"
    exit 1
fi
echo "   ✓ Configuration nginx valide"
echo ""

# 4. Recharger nginx
echo "4. Rechargement de nginx..."
sudo systemctl reload nginx
echo "   ✓ nginx rechargé"
echo ""

# 5. Tester
echo "5. Test avec Playwright..."
cd /tmp/playwright-test
node test_localhost.js 2>&1 | grep -E "✓|✗|Total:"

echo ""
echo "=========================================="
echo "  ✓ Déploiement terminé"
echo "=========================================="
echo ""
echo "Site accessible sur: http://localhost"
echo ""
echo "Pour precogn.org:"
echo "1. Configurer le DNS pour pointer vers 213.32.16.118"
echo "2. Installer certbot: sudo apt-get install certbot python3-certbot-nginx"
echo "3. Obtenir le certificat: sudo certbot --nginx -d precogn.org"
echo ""

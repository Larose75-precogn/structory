#!/bin/bash

# Script de validation complet pour PreCogn
# Vérifie que tout fonctionne avant et après déploiement

set -e

PROJECT_DIR="/home/ubuntu/projects/structory"
GODOT="/tmp/godot"
WORKER_DIR="$PROJECT_DIR/worker"
EXPORT_DIR="$PROJECT_DIR/export/web"

echo "=========================================="
echo "  Validation du projet PreCogn"
echo "=========================================="
echo ""

# 1. Vérifier Godot
echo "1. Vérification de Godot..."
if [ -x "$GODOT" ]; then
    echo "   ✓ Godot trouvé: $GODOT"
    $GODOT --version
else
    echo "   ❌ Godot non trouvé"
    exit 1
fi
echo ""

# 2. Vérifier les fichiers du projet
echo "2. Vérification des fichiers..."
cd "$PROJECT_DIR"
for file in project.godot Main.tscn flow.gd atom.gd main.gd ui.gd constants.gd; do
    if [ -f "$file" ]; then
        echo "   ✓ $file"
    else
        echo "   ❌ $file manquant"
        exit 1
    fi
done
echo ""

# 3. Lancer le projet en headless
echo "3. Test du projet en mode headless..."
timeout 5 $GODOT --headless --quit 2>&1 | tee /tmp/godot_test.log
if grep -qi "error\|fail" /tmp/godot_test.log | grep -v "error-stack-parser"; then
    echo "   ❌ Erreurs détectées:"
    grep -i "error\|fail" /tmp/godot_test.log | grep -v "error-stack-parser"
    exit 1
else
    echo "   ✓ Projet lancé sans erreurs"
fi
echo ""

# 4. Exporter pour le Web
echo "4. Export Web..."
rm -rf "$EXPORT_DIR"/*
$GODOT --headless --export-release "Web" 2>&1 | tee /tmp/export_test.log
if [ -f "$EXPORT_DIR/index.html" ]; then
    echo "   ✓ Export réussi"
    ls -lh "$EXPORT_DIR" | grep -E "index\.(html|wasm|pck)"
else
    echo "   ❌ Export échoué"
    exit 1
fi
echo ""

# 5. Préparer pour le déploiement
echo "5. Préparation du déploiement..."
cp "$EXPORT_DIR"/* "$WORKER_DIR/public/"
cd "$WORKER_DIR/public"
gzip -k index.wasm
mv index.wasm.gz index.wasm
echo "   ✓ Fichiers préparés"
ls -lh index.wasm
echo ""

# 6. Déployer
echo "6. Déploiement..."
cd "$WORKER_DIR"
export CLOUDFLARE_API_TOKEN="cfut_rdLcySG8AAKVeVt5fJr5OKQOB5lZCKWMj2CFRHUf45ffdc50"
npx wrangler deploy 2>&1 | tail -5
echo ""

# 7. Vérifier le site
echo "7. Vérification du site..."
sleep 3
HTTP_CODE=$(curl -sI https://precogn.org | head -1 | awk '{print $2}')
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✓ Site accessible (HTTP $HTTP_CODE)"
else
    echo "   ❌ Site inaccessible (HTTP $HTTP_CODE)"
    exit 1
fi

# Vérifier les headers
echo "   Vérification des headers COOP/COEP..."
if curl -sI https://precogn.org | grep -q "cross-origin-opener-policy: same-origin"; then
    echo "   ✓ COOP présent"
else
    echo "   ❌ COOP manquant"
    exit 1
fi

if curl -sI https://precogn.org | grep -q "cross-origin-embedder-policy: require-corp"; then
    echo "   ✓ COEP présent"
else
    echo "   ❌ COEP manquant"
    exit 1
fi
echo ""

echo "=========================================="
echo "  ✓ Validation complète réussie"
echo "=========================================="
echo ""
echo "Site: https://precogn.org"
echo ""

#!/bin/bash

# Script de validation complet avec capture d'écran pour PreCogn
# Lance Godot avec Xvfb, capture une capture d'écran, analyse et déploie

set -e

PROJECT_DIR="/home/ubuntu/projects/structory"
GODOT="/tmp/godot"
DISPLAY_NUM=":99"
SCREENSHOT_DIR="$PROJECT_DIR/screenshots"
WORKER_DIR="$PROJECT_DIR/worker"
EXPORT_DIR="$PROJECT_DIR/export/web"

echo "=========================================="
echo "  Validation complète PreCogn"
echo "=========================================="
echo ""

# Créer le dossier screenshots
mkdir -p "$SCREENSHOT_DIR"

# 1. Lancer Xvfb
echo "1. Démarrage de Xvfb..."
Xvfb $DISPLAY_NUM -screen 0 1920x1080x24 > /dev/null 2>&1 &
XVFB_PID=$!
sleep 2

if ! ps -p $XVFB_PID > /dev/null; then
    echo "   ❌ Échec du démarrage de Xvfb"
    exit 1
fi
echo "   ✓ Xvfb démarré (PID: $XVFB_PID)"

export DISPLAY=$DISPLAY_NUM

# 2. Lancer Godot et capturer les logs
echo ""
echo "2. Lancement de Godot..."
cd "$PROJECT_DIR"
timeout 10 $GODOT --windowed --resolution 1920x1080 2>&1 | tee /tmp/godot_full_test.log &
GODOT_PID=$!

# Attendre que Godot se charge et capture la capture d'écran
echo "   Attente du chargement..."
sleep 5

# 3. Récupérer la capture d'écran
echo ""
echo "3. Récupération de la capture d'écran..."
GODOT_SCREENSHOT="/home/ubuntu/.local/share/godot/app_userdata/PreCogn/screenshot.png"
if [ -f "$GODOT_SCREENSHOT" ]; then
    cp "$GODOT_SCREENSHOT" "$SCREENSHOT_DIR/test_render.png"
    echo "   ✓ Capture sauvegardée: $SCREENSHOT_DIR/test_render.png"
else
    echo "   ⚠ Capture d'écran Godot non trouvée"
fi

# Arrêter Godot
kill $GODOT_PID 2>/dev/null || true
wait $GODOT_PID 2>/dev/null || true

# 4. Analyser la capture d'écran
echo ""
echo "4. Analyse de la capture d'écran..."
python3 << 'PYEOF'
from PIL import Image

try:
    img = Image.open('/home/ubuntu/projects/structory/screenshots/test_render.png')
    pixels = list(img.getdata())
    non_black = sum(1 for p in pixels if p[0] > 10 or p[1] > 10 or p[2] > 10)
    total = len(pixels)
    percentage = non_black / total * 100
    
    print(f"   Pixels non-noirs: {percentage:.2f}%")
    
    if percentage < 1:
        print("   ⚠ L'image est presque noire - le rendu pourrait ne pas fonctionner")
        exit(1)
    else:
        print("   ✓ L'image contient du contenu visible")
        
    # Sauvegarder un aperçu
    img.thumbnail((400, 225))
    img.save('/home/ubuntu/projects/structory/screenshots/preview.png')
    print("   ✓ Aperçu sauvegardé")
    
except Exception as e:
    print(f"   ❌ Erreur lors de l'analyse: {e}")
    exit(1)
PYEOF

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Échec de l'analyse de la capture d'écran"
    kill $XVFB_PID 2>/dev/null || true
    exit 1
fi

# 5. Vérifier les erreurs dans les logs
echo ""
echo "5. Vérification des logs..."
if grep -i "error" /tmp/godot_full_test.log | grep -v "error-stack-parser" | grep -v "ALSA" | grep -v "audio" > /dev/null; then
    echo "   ⚠ Erreurs détectées:"
    grep -i "error" /tmp/godot_full_test.log | grep -v "error-stack-parser" | grep -v "ALSA" | grep -v "audio" | head -5
else
    echo "   ✓ Aucune erreur critique"
fi

# 6. Arrêter Xvfb
echo ""
echo "6. Arrêt de Xvfb..."
kill $XVFB_PID
wait $XVFB_PID 2>/dev/null || true
echo "   ✓ Xvfb arrêté"

# 7. Export Web
echo ""
echo "7. Export Web..."
rm -rf "$EXPORT_DIR"/*
$GODOT --headless --export-release "Web" 2>&1 | tee /tmp/export_final.log | tail -5

if [ ! -f "$EXPORT_DIR/index.html" ]; then
    echo "   ❌ Export échoué"
    exit 1
fi
echo "   ✓ Export réussi"

# 8. Préparer le déploiement
echo ""
echo "8. Préparation du déploiement..."
cp "$EXPORT_DIR"/* "$WORKER_DIR/public/"
cd "$WORKER_DIR/public"
gzip -k index.wasm
mv index.wasm.gz index.wasm
echo "   ✓ Fichiers préparés"

# 9. Déployer
echo ""
echo "9. Déploiement..."
cd "$WORKER_DIR"
export CLOUDFLARE_API_TOKEN="cfut_rdLcySG8AAKVeVt5fJr5OKQOB5lZCKWMj2CFRHUf45ffdc50"
npx wrangler deploy 2>&1 | tail -3

# 10. Vérifier le site
echo ""
echo "10. Vérification du site..."
sleep 3
HTTP_CODE=$(curl -sI https://precogn.org | head -1 | awk '{print $2}')
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✓ Site accessible (HTTP $HTTP_CODE)"
else
    echo "   ❌ Site inaccessible (HTTP $HTTP_CODE)"
    exit 1
fi

# Vérifier les headers
if curl -sI https://precogn.org | grep -q "cross-origin-opener-policy: same-origin"; then
    echo "   ✓ Headers COOP/COEP présents"
else
    echo "   ❌ Headers COOP/COEP manquants"
    exit 1
fi

echo ""
echo "=========================================="
echo "  ✓ Validation complète réussie"
echo "=========================================="
echo ""
echo "Site: https://precogn.org"
echo "Capture d'écran: $SCREENSHOT_DIR/test_render.png"
echo "Aperçu: $SCREENSHOT_DIR/preview.png"
echo ""

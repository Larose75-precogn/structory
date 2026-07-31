#!/bin/bash

# Script de test avec affichage virtuel pour PreCogn
# Lance Godot avec Xvfb et capture une capture d'écran

set -e

PROJECT_DIR="/home/ubuntu/projects/structory"
GODOT="/tmp/godot"
DISPLAY_NUM=":99"
SCREENSHOT_DIR="$PROJECT_DIR/screenshots"

echo "=========================================="
echo "  Test avec affichage virtuel"
echo "=========================================="
echo ""

# Créer le dossier screenshots
mkdir -p "$SCREENSHOT_DIR"

# Lancer Xvfb en arrière-plan
echo "1. Démarrage de Xvfb..."
Xvfb $DISPLAY_NUM -screen 0 1920x1080x24 &
XVFB_PID=$!
sleep 2

# Vérifier que Xvfb tourne
if ps -p $XVFB_PID > /dev/null; then
    echo "   ✓ Xvfb démarré (PID: $XVFB_PID)"
else
    echo "   ❌ Échec du démarrage de Xvfb"
    exit 1
fi

# Exporter la variable DISPLAY
export DISPLAY=$DISPLAY_NUM

# Lancer Godot et capturer les logs
echo ""
echo "2. Lancement de Godot..."
cd "$PROJECT_DIR"
timeout 10 $GODOT --windowed --resolution 1920x1080 2>&1 | tee /tmp/godot_xvfb.log &
GODOT_PID=$!

# Attendre que Godot se charge
echo "   Attente du chargement..."
sleep 5

# Capturer une capture d'écran
echo ""
echo "3. Capture d'écran..."
if command -v import &> /dev/null; then
    import -window root "$SCREENSHOT_DIR/godot_render.png"
    echo "   ✓ Capture sauvegardée: $SCREENSHOT_DIR/godot_render.png"
elif command -v scrot &> /dev/null; then
    scrot "$SCREENSHOT_DIR/godot_render.png"
    echo "   ✓ Capture sauvegardée: $SCREENSHOT_DIR/godot_render.png"
else
    echo "   ⚠ Aucun outil de capture disponible"
    echo "   Installation de imagemagick..."
    sudo apt-get install -y imagemagick > /dev/null 2>&1
    import -window root "$SCREENSHOT_DIR/godot_render.png"
    echo "   ✓ Capture sauvegardée: $SCREENSHOT_DIR/godot_render.png"
fi

# Arrêter Godot
echo ""
echo "4. Arrêt de Godot..."
kill $GODOT_PID 2>/dev/null || true
wait $GODOT_PID 2>/dev/null || true

# Arrêter Xvfb
echo ""
echo "5. Arrêt de Xvfb..."
kill $XVFB_PID
wait $XVFB_PID 2>/dev/null || true

echo ""
echo "=========================================="
echo "  Test terminé"
echo "=========================================="
echo ""
echo "Capture d'écran: $SCREENSHOT_DIR/godot_render.png"
echo ""

# Vérifier les erreurs dans les logs
echo "Analyse des logs..."
if grep -qi "error\|fail" /tmp/godot_xvfb.log | grep -v "error-stack-parser"; then
    echo "⚠ Erreurs détectées:"
    grep -i "error\|fail" /tmp/godot_xvfb.log | grep -v "error-stack-parser" | head -10
else
    echo "✓ Aucune erreur détectée"
fi

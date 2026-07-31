#!/bin/bash

# Script de test pour PreCogn
# Lance le projet et capture les erreurs

cd /home/ubuntu/projects/structory

echo "=== Test du projet PreCogn ==="
echo ""

# Test 1: Vérifier que le projet se lance
echo "Test 1: Lancement du projet..."
timeout 5 /tmp/godot --headless --quit 2>&1 | tee /tmp/test1.log

if grep -qi "error" /tmp/test1.log; then
    echo "❌ Erreurs détectées:"
    grep -i "error" /tmp/test1.log
else
    echo "✓ Pas d'erreurs au lancement"
fi

echo ""

# Test 2: Vérifier les scripts
echo "Test 2: Vérification des scripts..."
for script in constants.gd main.gd flow.gd atom.gd ui.gd; do
    if [ -f "$script" ]; then
        echo "✓ $script existe"
    else
        echo "❌ $script manquant"
    fi
done

echo ""

# Test 3: Vérifier les scènes
echo "Test 3: Vérification des scènes..."
for scene in Main.tscn flow.tscn Atom.tscn; do
    if [ -f "$scene" ]; then
        echo "✓ $scene existe"
    else
        echo "❌ $scene manquant"
    fi
done

echo ""

# Test 4: Export Web
echo "Test 4: Export Web..."
if [ -d "export/web" ] && [ -f "export/web/index.html" ]; then
    echo "✓ Export Web présent"
    ls -lh export/web/ | head -10
else
    echo "❌ Export Web manquant"
fi

echo ""
echo "=== Test terminé ==="

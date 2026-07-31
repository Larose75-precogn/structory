#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXPORT_DIR="$SCRIPT_DIR/export/web"

echo "=== PreCogn Build ==="

# Check Godot
if command -v godot &> /dev/null; then
    GODOT_CMD="godot"
elif command -v godot4 &> /dev/null; then
    GODOT_CMD="godot4"
else
    echo "ERROR: Godot not found"
    exit 1
fi

echo "Using: $GODOT_CMD"

# Import
echo "Importing resources..."
$GODOT_CMD --headless --path "$SCRIPT_DIR" --import

# Export
echo "Exporting for Web..."
mkdir -p "$EXPORT_DIR"
$GODOT_CMD --headless --path "$SCRIPT_DIR" --export-release "Web"

if [ -f "$EXPORT_DIR/index.html" ]; then
    echo "SUCCESS: Export ready in $EXPORT_DIR"
else
    echo "ERROR: Export failed"
    exit 1
fi

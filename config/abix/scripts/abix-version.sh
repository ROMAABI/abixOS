#!/usr/bin/env bash
# abix-version.sh - AbixOS Version Information

set -euo pipefail

CONFIG_DIR="${HOME}/.config/abix"
CACHE_DIR="${HOME}/.cache/abix"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  AbixOS Version Information${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${GREEN}AbixOS${NC} - HyDE-inspired configuration"
echo "Version: 1.0.0"
echo ""

echo "Directories:"
echo "  Config:   $CONFIG_DIR"
echo "  Scripts:  $CONFIG_DIR/scripts"
echo "  Themes:   $CONFIG_DIR/themes"
echo "  Cache:    $CACHE_DIR"
echo ""

echo "System Info:"
echo "  Shell:    $SHELL"
echo "  User:     $USER"
echo "  Home:     $HOME"
echo ""

# Hyprland version if running
if command -v hyprctl &>/dev/null; then
    if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
        echo -e "${GREEN}Hyprland:${NC}"
        hyprctl version 2>/dev/null | head -3 || echo "  Not available"
    else
        echo -e "${YELLOW}Hyprland:${NC} Not running"
    fi
else
    echo -e "${YELLOW}Hyprland:${NC} Not installed"
fi
echo ""

# Waybar status
if pgrep waybar &>/dev/null; then
    echo -e "${GREEN}Waybar:    Running${NC}"
else
    echo -e "${YELLOW}Waybar:    Not running${NC}"
fi

# swaync status
if pgrep swaync &>/dev/null; then
    echo -e "${GREEN}swaync:    Running${NC}"
else
    echo -e "${YELLOW}swaync:    Not running${NC}"
fi

echo ""
echo "Config files:"
shopt -s nullglob
for f in "$CONFIG_DIR"/*.conf "$CONFIG_DIR"/*.sh; do
    echo "  - $(basename "$f")"
done
shopt -u nullglob

echo ""
echo -e "${BLUE}========================================${NC}"
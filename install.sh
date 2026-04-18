#!/bin/bash
# AbixOS Installation Script
# ============================================
# Clone: git clone git@github.com:ROMAABI/abixOS.git
# Run: ./install.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_NAME="abixOS"
TARGET_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config.backup.$(date +%Y%m%d_%H%M%S)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  AbixOS Installation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ============================================
# Check for required commands
# ============================================
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${YELLOW}Warning: $1 not found. Some features may not work.${NC}"
    fi
}

echo -e "${GREEN}[1/6] Checking dependencies...${NC}"
check_command "hyprctl"
check_command "waybar"
check_command "rofi"
check_command "fish"
check_command "zsh"

# ============================================
# Backup existing config
# ============================================
echo -e "${GREEN}[2/6] Backing up existing configs...${NC}"

CONFIG_DIRS=("hypr" "waybar" "rofi" "kitty" "fish" "zsh" "abix")
BACKUPED=false

for dir in "${CONFIG_DIRS[@]}"; do
    if [ -d "$TARGET_DIR/$dir" ]; then
        if [ "$BACKUPED" = false ]; then
            mkdir -p "$BACKUP_DIR"
            BACKUPED=true
        fi
        echo -e "  ${YELLOW}Backing up $dir...${NC}"
        cp -r "$TARGET_DIR/$dir" "$BACKUP_DIR/"
    fi
done

if [ "$BACKUPED" = true ]; then
    echo -e "  ${GREEN}Backup created at: $BACKUP_DIR${NC}"
else
    echo -e "  ${GREEN}No existing configs found.${NC}"
fi

# ============================================
# Create symlinks or copy
# ============================================
echo -e "${GREEN}[3/6] Installing configs...${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CONFIG="$SCRIPT_DIR/config"
REPO_LOCAL="$SCRIPT_DIR/local"

# Create directories
mkdir -p "$TARGET_DIR/hypr"
mkdir -p "$TARGET_DIR/waybar"
mkdir -p "$TARGET_DIR/rofi"
mkdir -p "$TARGET_DIR/kitty"
mkdir -p "$TARGET_DIR/fish"
mkdir -p "$TARGET_DIR/zsh"
mkdir -p "$TARGET_DIR/abix"
mkdir -p "$HOME/.local/share/hypr"

# Copy config files
copy_config() {
    local src="$1"
    local dest="$2"
    if [ -d "$src" ]; then
        cp -r "$src/"* "$dest/" 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} $dest"
    fi
}

# Hyprland
if [ -d "$REPO_CONFIG/hypr" ]; then
    copy_config "$REPO_CONFIG/hypr" "$TARGET_DIR/hypr"
fi

# Waybar
[ -d "$REPO_CONFIG/waybar" ] && copy_config "$REPO_CONFIG/waybar" "$TARGET_DIR/waybar"

# Rofi
[ -d "$REPO_CONFIG/rofi" ] && copy_config "$REPO_CONFIG/rofi" "$TARGET_DIR/rofi"

# Kitty
[ -d "$REPO_CONFIG/kitty" ] && copy_config "$REPO_CONFIG/kitty" "$TARGET_DIR/kitty"

# HyDE
[ -d "$REPO_CONFIG/hyde" ] && copy_config "$REPO_CONFIG/hyde" "$TARGET_DIR/hyde"

# Abix (custom layer)
[ -d "$REPO_CONFIG/abix" ] && copy_config "$REPO_CONFIG/abix" "$TARGET_DIR/abix"

# Hypr shared configs
if [ -d "$REPO_LOCAL/hypr" ]; then
    copy_config "$REPO_LOCAL/hypr" "$HOME/.local/share/hypr"
fi

# ============================================
# Install scripts
# ============================================
echo -e "${GREEN}[4/6] Installing scripts...${NC}"

mkdir -p "$HOME/.local/bin"

if [ -d "$SCRIPT_DIR/scripts" ]; then
    for script in "$SCRIPT_DIR/scripts"/*; do
        if [ -f "$script" ] && [ -x "$script" ]; then
            cp "$script" "$HOME/.local/bin/"
            echo -e "  ${GREEN}✓${NC} $(basename $script)"
        fi
    done
fi

# ============================================
# Reload services
# ============================================
echo -e "${GREEN}[5/6] Reloading services...${NC}"

# Reload Hyprland
if command -v hyprctl &> /dev/null; then
        hyprctl reload
    echo -e "  ${GREEN}✓${NC} Hyprland config reloaded"
fi

# Restart Waybar
if pgrep waybar &> /dev/null; then
    killall waybar 2>/dev/null || true
    waybar & 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Waybar restarted"
fi

# ============================================
# Summary
# ============================================
echo ""
echo -e "${GREEN}[6/6] Installation complete!${NC}"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "  ${GREEN}Configs installed:${NC}"
echo "    - Hyprland: $TARGET_DIR/hypr/"
echo "    - Waybar:   $TARGET_DIR/waybar/"
echo "    - Rofi:     $TARGET_DIR/rofi/"
echo "    - Kitty:    $TARGET_DIR/kitty/"
echo "    - Fish:     $TARGET_DIR/fish/"
echo "    - Zsh:      $TARGET_DIR/zsh/"
echo "    - Abix:     $TARGET_DIR/abix/"
echo ""
echo -e "  ${GREEN}Scripts installed:${NC}"
echo "    - $HOME/.local/bin/abix-shell"
echo "    - $HOME/.local/bin/abixctl"
echo ""

if [ "$BACKUPED" = true ]; then
    echo -e "${YELLOW}Backup location: $BACKUP_DIR${NC}"
    echo ""
fi

echo -e "${BLUE}To switch themes:${NC}"
echo "  abix-shell themeselect"
echo ""
echo -e "${BLUE}To reload Waybar:${NC}"
echo "  killall waybar && waybar &"
echo ""
echo -e "${GREEN}Enjoy your AbixOS setup!${NC}"

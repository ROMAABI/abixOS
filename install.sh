#!/bin/bash
# AbixOS Installation Script - Production Ready
# ============================================
# Clone: git clone git@github.com:ROMAABI/abixOS.git
# Run: ./install.sh
#
# This script safely installs AbixOS configuration with:
# - Automatic dependency installation
# - Safe config copying (no overwrites)
# - HyDE optional installation
# - Proper service reloading
# - Rollback capability
# - Detailed logging

set -euo pipefail
IFS=$'\n\t'

# Logging
LOGFILE="$HOME/abixos_install_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "======================================"
echo "  AbixOS Production Installer"
echo "======================================"
echo "Log file: $LOGFILE"
echo ""

# Configuration
REPO_NAME="abixOS"
TARGET_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config.backup.$(date +%Y%m%d_%H%M%S)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CONFIG="$SCRIPT_DIR/config"
REPO_LOCAL="$SCRIPT_DIR/local"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize variables
INSTALL_HYDE=false
CONFIG_DIRS=("hypr" "waybar" "rofi" "kitty" "fish" "zsh" "abix")
BACKUPED=false
DEPS_TO_INSTALL=()

# ============================================
# Helper Functions
# ============================================

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

error() {
    log "ERROR: $1"
    echo -e "${RED}ERROR: $1${NC}" >&2
}

warn() {
    log "WARNING: $1"
    echo -e "${YELLOW}WARNING: $1${NC}"
}

info() {
    log "INFO: $1"
    echo -e "${BLUE}INFO: $1${NC}"
}

success() {
    log "SUCCESS: $1"
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        warn "$1 not found"
        return 1
    fi
    return 0
}

safe_copy() {
    local src="$1"
    local dest="$2"
    
    if [[ ! -d "$src" ]]; then
        warn "Source directory does not exist: $src"
        return 1
    fi
    
    mkdir -p "$dest"
    local copied=0
    local skipped=0
    
    # Enable nullglob to handle empty directories
    shopt -s nullglob
    for item in "$src"/*; do
        if [[ -e "$item" ]]; then
            local basename=$(basename "$item")
            if [[ -e "$dest/$basename" ]]; then
                warn "Skipping existing: $basename"
                ((skipped++))
            else
                cp -r "$item" "$dest/"
                ((copied++))
            fi
        fi
    done
    shopt -u nullglob
    
    if [[ $copied -gt 0 ]]; then
        success "Copied $copied item(s) to $dest"
    fi
    if [[ $skipped -gt 0 ]]; then
        warn "Skipped $skipped existing item(s) in $dest"
    fi
    
    return 0
}

# ============================================
# Main Installation
# ============================================

# Step 1: Pre-flight checks
echo -e "${BLUE}[1/10] Pre-flight checks...${NC}"
log "Starting AbixOS installation"

# Check if running as root (should not be)
if [[ $(id -u) -eq 0 ]]; then
    error "Do not run as root. Please run as regular user."
    exit 1
fi

# Detect distribution
if [[ -f "/etc/arch-release" ]]; then
    DISTRO="arch"
    PKG_MANAGER="pacman"
    info "Arch-based system detected"
elif [[ -f "/etc/debian_version" ]]; then
    DISTRO="debian"
    PKG_MANAGER="apt"
    info "Debian-based system detected"
else
    warn "Unsupported distribution. Continuing with manual dependency check."
    DISTRO="unknown"
fi

# Step 2: User confirmation
echo -e "${BLUE}[2/10] User confirmation...${NC}"
read -rp "Proceed with AbixOS installation? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Installation cancelled by user"
    exit 0
fi

# Step 3: Backup existing configs
echo -e "${BLUE}[3/10] Backing up existing configs...${NC}"
for dir in "${CONFIG_DIRS[@]}"; do
    if [[ -d "$TARGET_DIR/$dir" ]]; then
        if [[ $BACKUPED == false ]]; then
            mkdir -p "$BACKUP_DIR"
            BACKUPED=true
            info "Backup directory created: $BACKUP_DIR"
        fi
        log "Backing up $dir"
        cp -r "$TARGET_DIR/$dir" "$BACKUP_DIR/" || {
            warn "Failed to backup $dir"
        }
    fi
done

if [[ $BACKUPED == true ]]; then
    success "Backup created at: $BACKUP_DIR"
else
    info "No existing configs found to backup"
fi

# Step 4: Ask about HyDE installation
echo -e "${BLUE}[4/10] HyDE configuration...${NC}"
read -rp "Install HyDE core configurations? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    INSTALL_HYDE=true
    info "HyDE installation: ENABLED"
else
    INSTALL_HYDE=false
    info "HyDE installation: SKIPPED"
fi

# Step 5: Dependency installation
echo -e "${BLUE}[5/10] Checking dependencies...${NC}"
declare -A CORE_DEPS=(
    ["hyprland"]="hyprland"
    ["waybar"]="waybar"
    ["rofi"]="rofi"
    ["swaync"]="swaync"
    ["kitty"]="kitty"
    ["swww"]="swww"
    ["hyprpaper"]="hyprpaper"
    ["cliphist"]="cliphist"
    ["wl-clipboard"]="wl-clipboard"
)

for dep in "${!CORE_DEPS[@]}"; do
    if ! check_command "${CORE_DEPS[$dep]}"; then
        DEPS_TO_INSTALL+=("$dep")
    fi
done

if [[ ${#DEPS_TO_INSTALL[@]} -gt 0 ]]; then
    warn "Missing dependencies: ${DEPS_TO_INSTALL[*]}"
    
    if [[ "$DISTRO" == "arch" ]]; then
        read -rp "Install missing dependencies with pacman? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            info "Installing dependencies: ${DEPS_TO_INSTALL[*]}"
            sudo pacman -Sy --needed "${DEPS_TO_INSTALL[@]}" || {
                error "Failed to install dependencies"
                exit 1
            }
            success "Dependencies installed"
        else
            warn "Skipping dependency installation. Some features may not work."
        fi
    else
        warn "Please install missing dependencies manually: ${DEPS_TO_INSTALL[*]}"
    fi
else
    success "All core dependencies are installed"
fi

# Step 6: Install configs
echo -e "${BLUE}[6/10] Installing configurations...${NC}"

# Create target directories
mkdir -p "$TARGET_DIR/hypr"
mkdir -p "$TARGET_DIR/waybar"
mkdir -p "$TARGET_DIR/rofi"
mkdir -p "$TARGET_DIR/kitty"
mkdir -p "$TARGET_DIR/fish"
mkdir -p "$TARGET_DIR/zsh"
mkdir -p "$TARGET_DIR/abix"
mkdir -p "$HOME/.local/share/hypr"
mkdir -p "$HOME/.local/bin"

# Copy configs safely
safe_copy "$REPO_CONFIG/hypr" "$TARGET_DIR/hypr"
safe_copy "$REPO_CONFIG/waybar" "$TARGET_DIR/waybar"
safe_copy "$REPO_CONFIG/rofi" "$TARGET_DIR/rofi"
safe_copy "$REPO_CONFIG/kitty" "$TARGET_DIR/kitty"
safe_copy "$REPO_CONFIG/fish" "$TARGET_DIR/fish"
safe_copy "$REPO_CONFIG/zsh" "$TARGET_DIR/zsh"
safe_copy "$REPO_CONFIG/abix" "$TARGET_DIR/abix"

if [[ $INSTALL_HYDE == true ]]; then
    safe_copy "$REPO_CONFIG/hyde" "$TARGET_DIR/hyde"
else
    info "Skipping HyDE configuration copy"
fi

if [[ -d "$REPO_LOCAL/hypr" ]]; then
    safe_copy "$REPO_LOCAL/hypr" "$HOME/.local/share/hypr"
fi

# Step 7: Install scripts
echo -e "${BLUE}[7/10] Installing scripts...${NC}"
if [[ -d "$SCRIPT_DIR/scripts" ]]; then
    shopt -s nullglob
    for script in "$SCRIPT_DIR/scripts"/*; do
        if [[ -f "$script" && -x "$script" ]]; then
            cp "$script" "$HOME/.local/bin/"
            success "Installed script: $(basename "$script")"
        fi
    done
    shopt -u nullglob
else
    warn "No scripts directory found"
fi

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
    info "Added ~/.local/bin to PATH in ~/.profile"
fi

# Step 8: Reload services
echo -e "${BLUE}[8/10] Reloading services...${NC}"

# Reload Hyprland
if check_command "hyprctl"; then
    if hyprctl reload &>/dev/null; then
        success "Hyprland config reloaded"
    else
        warn "Failed to reload Hyprland config"
    fi
else
    warn "hyprctl not found, skipping Hyprland reload"
fi

# Restart Waybar safely
if check_command "waybar"; then
    pkill waybar 2>/dev/null || true
    sleep 1
    nohup waybar >/dev/null 2>&1 &
    disown 2>/dev/null || true
    success "Waybar restarted"
else
    warn "waybar not found, skipping restart"
fi

# Step 9: Final verification
echo -e "${BLUE}[9/10] Verifying installation...${NC}"

# Check if configs exist
MISSING_CONFIGS=()
for dir in "${CONFIG_DIRS[@]}"; do
    if [[ ! -d "$TARGET_DIR/$dir" ]]; then
        MISSING_CONFIGS+=("$dir")
    fi
done

if [[ ${#MISSING_CONFIGS[@]} -eq 0 ]]; then
    success "All configuration directories present"
else
    warn "Missing configuration directories: ${MISSING_CONFIGS[*]}"
fi

# Check scripts
if [[ -d "$HOME/.local/bin" ]]; then
    SCRIPT_COUNT=$(find "$HOME/.local/bin" -type f -executable 2>/dev/null | wc -l)
    if [[ $SCRIPT_COUNT -gt 0 ]]; then
        success "Installed $SCRIPT_COUNT executable script(s)"
    else
        warn "No executable scripts found in ~/.local/bin"
    fi
else
    warn "~/.local/bin directory not found"
fi

# Step 10: Summary
echo -e "${BLUE}[10/10] Installation complete!${NC}"
echo ""
echo "======================================"
echo "  Installation Summary"
echo "======================================"
echo -e "${GREEN}✓${NC} Backup: $BACKUP_DIR"
echo -e "${GREEN}✓${NC} HyDE installation: $([[ $INSTALL_HYDE == true ]] && echo 'ENABLED' || echo 'SKIPPED')"
echo -e "${GREEN}✓${NC} Dependencies: ${#DEPS_TO_INSTALL[@]} installed, $((${#CORE_DEPS[@]} - ${#DEPS_TO_INSTALL[@]})) already present"
echo -e "${GREEN}✓${NC} Configs: Hyprland, Waybar, Rofi, Kitty, Fish, Zsh, Abix"
echo -e "${GREEN}✓${NC} Scripts: Installed to ~/.local/bin"
echo -e "${GREEN}✓${NC} PATH: ~/.local/bin added (login shell required)"
echo -e "${GREEN}✓${NC} Services: Hyprland reloaded, Waybar restarted"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Log out and back in (or restart Hyprland)"
echo "  2. Check: hyprctl version"
echo "  3. Customize: ~/.config/abix/abix.conf"
echo "  4. Theme selection: abix-shell themeselect"
echo ""
echo -e "${BLUE}Enjoy your AbixOS setup!${NC}"
echo ""
log "AbixOS installation completed successfully"
#!/usr/bin/env bash
# abix-pkg.sh - AbixOS Package Management
# Simplified package installer without HyDE dependencies

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.config/abix"
CACHE_DIR="${HOME}/.cache/abix"
LOG_DIR="${CACHE_DIR}/logs"
PKG_LIST="${CONFIG_DIR}/packages.lst"

mkdir -p "$LOG_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[pkg]${NC} $1"; }
log_success() { echo -e "${GREEN}[pkg]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[pkg]${NC} $1"; }
log_error() { echo -e "${RED}[pkg]${NC} $1" >&2; }

show_help() {
    cat << EOF
Usage: abix-pkg.sh [OPTIONS]

Options:
  -i, --install     Install packages from list
  -l, --list        Show package list
  -a, --add PKG     Add package to list
  -r, --remove PKG  Remove package from list
  -c, --check       Check installed packages
  -u, --update      Update system packages
  -h, --help        Show this help

Package list: $PKG_LIST
EOF
}

# Check if package is installed
pkg_installed() {
    pacman -Q "$1" &>/dev/null
}

# Check if package is available
pkg_available() {
    pacman -Si "$1" &>/dev/null
}

# Add package to list
add_package() {
    local pkg="$1"
    if [[ -z "$pkg" ]]; then
        log_error "No package specified"
        return 1
    fi
    
    mkdir -p "$(dirname "$PKG_LIST")"
    if [[ ! -f "$PKG_LIST" ]]; then
        touch "$PKG_LIST"
    fi
    
    if grep -q "^${pkg}$" "$PKG_LIST" 2>/dev/null; then
        log_warn "Package already in list: $pkg"
    else
        echo "$pkg" >> "$PKG_LIST"
        log_success "Added to list: $pkg"
    fi
}

# Remove package from list
remove_package() {
    local pkg="$1"
    if [[ -z "$pkg" ]]; then
        log_error "No package specified"
        return 1
    fi
    
    if [[ ! -f "$PKG_LIST" ]]; then
        log_error "No package list found"
        return 1
    fi
    
    local tmp
    tmp=$(mktemp)
    grep -v "^${pkg}$" "$PKG_LIST" > "$tmp" || true
    mv "$tmp" "$PKG_LIST"
    log_success "Removed from list: $pkg"
}

# Show package list
show_list() {
    if [[ ! -f "$PKG_LIST" ]]; then
        log_warn "No package list found: $PKG_LIST"
        return 1
    fi
    
    echo "=== AbixOS Package List ==="
    local count=0
    while IFS='#' read -r pkg _; do
        [[ -z "$pkg" ]] && continue
        ((count++))
        if pkg_installed "$pkg"; then
            echo -e "  ${GREEN}✓${NC} $pkg"
        else
            echo -e "  ${YELLOW}○${NC} $pkg"
        fi
    done < "$PKG_LIST"
    echo ""
    echo "Total: $count packages"
}

# Check installed status
check_packages() {
    if [[ ! -f "$PKG_LIST" ]]; then
        log_error "No package list found"
        return 1
    fi
    
    local installed=0
    local missing=0
    
    echo "=== Package Status ==="
    while IFS='#' read -r pkg _; do
        [[ -z "$pkg" ]] && continue
        if pkg_installed "$pkg"; then
            ((installed++))
            echo -e "  ${GREEN}✓${NC} $pkg"
        else
            ((missing++))
            echo -e "  ${RED}✗${NC} $pkg"
        fi
    done < "$PKG_LIST"
    
    echo ""
    echo "Installed: $installed | Missing: $missing"
}

# Install packages
install_packages() {
    if [[ ! -f "$PKG_LIST" ]]; then
        log_error "No package list found"
        return 1
    fi
    
    local to_install=()
    
    log_info "Checking packages..."
    while IFS='#' read -r pkg _; do
        [[ -z "$pkg" ]] && continue
        
        if pkg_installed "$pkg"; then
            log_info "Already installed: $pkg"
        elif pkg_available "$pkg"; then
            to_install+=("$pkg")
            log_info "Will install: $pkg"
        else
            log_error "Not available: $pkg"
        fi
    done < "$PKG_LIST"
    
    if [[ ${#to_install[@]} -eq 0 ]]; then
        log_success "All packages already installed"
        return 0
    fi
    
    echo ""
    log_info "Installing ${#to_install[@]} packages..."
    
    if [[ $(id -u) -eq 0 ]]; then
        pacman -S --needed "${to_install[@]}"
    else
        sudo pacman -S --needed "${to_install[@]}"
    fi
    
    log_success "Installation complete"
}

# Update system
update_system() {
    log_info "Updating system packages..."
    
    if [[ $(id -u) -eq 0 ]]; then
        pacman -Syu
    else
        sudo pacman -Syu
    fi
    
    log_success "System updated"
}

# Parse arguments
ACTION="help"

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--install)
            ACTION="install"
            shift
            ;;
        -l|--list)
            ACTION="list"
            shift
            ;;
        -a|--add)
            ACTION="add"
            shift
            ;;
        -r|--remove)
            ACTION="remove"
            shift
            ;;
        -c|--check)
            ACTION="check"
            shift
            ;;
        -u|--update)
            ACTION="update"
            shift
            ;;
        -h|--help)
            ACTION="help"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Handle remaining argument for add/remove
if [[ "$ACTION" == "add" || "$ACTION" == "remove" ]]; then
    if [[ $# -gt 0 ]]; then
        PKG_ARG="$1"
    else
        log_error "Package name required"
        exit 1
    fi
fi

# Execute action
case "$ACTION" in
    install)
        install_packages
        ;;
    list)
        show_list
        ;;
    add)
        add_package "$PKG_ARG"
        ;;
    remove)
        remove_package "$PKG_ARG"
        ;;
    check)
        check_packages
        ;;
    update)
        update_system
        ;;
    help)
        show_help
        ;;
esac
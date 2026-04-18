#!/usr/bin/env bash
# abix-shell.sh - AbixOS Shell Configuration
# Configure shell without HyDE dependencies

set -euo pipefail

CONFIG_DIR="${HOME}/.config/abix"
SHELL_DIR="${CONFIG_DIR}/shell"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[shell]${NC} $1"; }
log_success() { echo -e "${GREEN}[shell]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[shell]${NC} $1"; }
log_error() { echo -e "${RED}[shell]${NC} $1" >&2; }

show_help() {
    cat << EOF
Usage: abix-shell.sh [OPTIONS]

Options:
  -s, --set SHELL    Set default shell (zsh/fish)
  -g, --get          Show current shell
  -p, --plugins      List/manage plugins
  -i, --install      Install shell dependencies
  -h, --help         Show this help

Supported shells: zsh, fish
EOF
}

# Get current shell
get_shell() {
    local current
    current=$(getent passwd "$USER" | cut -d: -f7)
    basename "$current"
}

# Set shell
set_shell() {
    local shell="$1"
    local shell_path
    
    case "$shell" in
        zsh)
            shell_path=$(command -v zsh)
            ;;
        fish)
            shell_path=$(command -v fish)
            ;;
        *)
            log_error "Unsupported shell: $shell"
            return 1
            ;;
    esac
    
    if [[ -z "$shell_path" ]]; then
        log_error "$shell is not installed"
        return 1
    fi
    
    local current_shell
    current_shell=$(get_shell)
    
    if [[ "$current_shell" == "$shell" ]]; then
        log_warn "$shell is already your default shell"
        return 0
    fi
    
    log_info "Setting $shell as default shell..."
    chsh -s "$shell_path"
    
    if [[ $? -eq 0 ]]; then
        log_success "$shell set as default shell"
    else
        log_error "Failed to set shell (may need sudo)"
    fi
}

# List plugins for a shell
list_plugins() {
    local shell="$1"
    local plugins_file="${SHELL_DIR}/${shell}/plugins.lst"
    
    if [[ ! -f "$plugins_file" ]]; then
        log_warn "No plugins list for $shell"
        return 1
    fi
    
    echo "=== $shell Plugins ==="
    while IFS='#' read -r plugin _; do
        [[ -z "$plugin" ]] && continue
        echo "  - $plugin"
    done < "$plugins_file"
}

# Install shell dependencies
install_deps() {
    log_info "Installing shell dependencies..."
    
    local zsh_deps=("zsh" "zsh-completions" "fzf" "bat" "exa" "starship")
    local fish_deps=("fish" "fzf" "bat" "exa" "starship")
    
    local to_install=()
    
    # Check zsh
    if command -v zsh &>/dev/null; then
        for dep in "${zsh_deps[@]}"; do
            if ! pacman -Q "$dep" &>/dev/null; then
                to_install+=("$dep")
            fi
        done
    fi
    
    # Check fish
    if command -v fish &>/dev/null; then
        for dep in "${fish_deps[@]}"; do
            if ! pacman -Q "$dep" &>/dev/null; then
                to_install+=("$dep")
            fi
        done
    fi
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Installing: ${to_install[*]}"
        if [[ $(id -u) -eq 0 ]]; then
            pacman -S --needed "${to_install[@]}"
        else
            sudo pacman -S --needed "${to_install[@]}"
        fi
    else
        log_success "All shell dependencies already installed"
    fi
}

# Parse arguments
ACTION="help"

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--set)
            ACTION="set"
            shift
            ;;
        -g|--get)
            ACTION="get"
            shift
            ;;
        -p|--plugins)
            ACTION="plugins"
            shift
            ;;
        -i|--install)
            ACTION="install"
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

# Handle argument for set action
if [[ "$ACTION" == "set" ]]; then
    if [[ $# -gt 0 ]]; then
        SHELL_ARG="$1"
    else
        log_error "Shell name required (zsh/fish)"
        exit 1
    fi
fi

# Handle argument for plugins action
if [[ "$ACTION" == "plugins" ]]; then
    if [[ $# -gt 0 ]]; then
        PLUGINS_ARG="$1"
    else
        PLUGINS_ARG=$(get_shell)
    fi
fi

# Execute action
case "$ACTION" in
    set)
        set_shell "$SHELL_ARG"
        ;;
    get)
        log_info "Current shell: $(get_shell)"
        ;;
    plugins)
        list_plugins "$PLUGINS_ARG"
        ;;
    install)
        install_deps
        ;;
    help)
        show_help
        ;;
esac
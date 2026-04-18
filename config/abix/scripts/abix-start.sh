#!/usr/bin/env bash
# abix-start.sh - AbixOS initialization and startup script
# Part of AbixOS - HyDE-inspired but independent

set -euo pipefail

# Configuration
ABIX_DIR="${HOME}/.config/abix"
SCRIPTS_DIR="${ABIX_DIR}/scripts"
CACHE_DIR="${HOME}/.cache/abix"
LOG_FILE="${CACHE_DIR}/startup.log"

# Create cache directory
mkdir -p "${CACHE_DIR}"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error() {
    echo "[ERROR] $1" | tee -a "$LOG_FILE" >&2
}

# Help message
show_help() {
    cat << EOF
Usage: abix-start.sh [OPTIONS]

Options:
  -f, --full         Full initialization (default)
  -q, --quick        Quick initialization (skip optional services)
  -s, --services     Start only services (no UI reload)
  -c, --check        Check system and show status
  -h, --help         Show this help message

This script initializes AbixOS on startup. It:
  - Creates necessary directories
  - Checks dependencies
  - Initializes services
  - Starts waybar
  - Sets initial wallpaper (if configured)
EOF
}

# Check dependencies
check_deps() {
    local missing=()
    
    # Core dependencies
    for cmd in hyprctl waybar; do
        if ! command -v "${cmd}" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "WARNING: Missing dependencies: ${missing[*]}"
        return 1
    fi
    
    return 0
}

# Create directories
init_dirs() {
    log "Initializing directories..."
    
    # Ensure Abix directories exist
    mkdir -p "${ABIX_DIR}/themes"
    mkdir -p "${ABIX_DIR}/wallpapers"
    mkdir -p "${ABIX_DIR}/scripts"
    mkdir -p "${ABIX_DIR}/icons"
    mkdir -p "${CACHE_DIR}"
    
    log "Directories initialized"
}

# Start waybar
start_waybar() {
    log "Starting waybar..."
    
    # Kill existing waybar instances
    pkill waybar 2>/dev/null || true
    sleep 0.5
    
    # Start waybar in background
    if command -v waybar &> /dev/null; then
        nohup waybar >/dev/null 2>&1 &
        log "Waybar started"
    else
        log "WARNING: waybar not found, skipping"
    fi
}

# Set initial wallpaper (if configured)
set_initial_wallpaper() {
    local wall_script="${SCRIPTS_DIR}/abix-wall.sh"
    
    if [[ -f "$wall_script" ]]; then
        # Check if there's a saved wallpaper preference
        local saved_wall="${CACHE_DIR}/wallpaper/current"
        if [[ -f "$saved_wall" ]]; then
            log "Setting saved wallpaper..."
            "$wall_script" "$(cat "$saved_wall")" 2>/dev/null || true
        fi
    fi
}

# Quick initialization - core services only
init_quick() {
    log "Starting AbixOS (quick mode)..."
    
    init_dirs
    check_deps || true
    start_waybar
    
    log "AbixOS quick initialization complete"
}

# Full initialization - all services
init_full() {
    log "Starting AbixOS (full mode)..."
    
    init_dirs
    
    if ! check_deps; then
        log "WARNING: Some dependencies missing, continuing anyway"
    fi
    
    # Start services
    start_waybar
    
    # Set initial wallpaper
    set_initial_wallpaper
    
    # Reload Hyprland to apply any config changes
    if command -v hyprctl &> /dev/null; then
        log "Reloading Hyprland..."
        hyprctl reload 2>/dev/null || true
    fi
    
    log "AbixOS full initialization complete"
}

# Start only services (no UI reload)
init_services() {
    log "Starting AbixOS services only..."
    
    init_dirs
    start_waybar
    
    log "Services started"
}

# Check system status
check_status() {
    echo "=== AbixOS Status Check ==="
    echo ""
    
    echo "Directories:"
    echo "  Abix config: ${ABIX_DIR} ($(test -d "$ABIX_DIR" && echo "exists" || echo "missing"))"
    echo "  Scripts:     ${SCRIPTS_DIR} ($(test -d "$SCRIPTS_DIR" && echo "exists" || echo "missing"))"
    echo "  Cache:      ${CACHE_DIR} ($(test -d "$CACHE_DIR" && echo "exists" || echo "missing"))"
    echo ""
    
    echo "Dependencies:"
    for cmd in hyprctl waybar swww swaync-client; do
        if command -v "${cmd}" &> /dev/null; then
            echo "  ✓ ${cmd}"
        else
            echo "  ✗ ${cmd} (not found)"
        fi
    done
    echo ""
    
    echo "Running Services:"
    if pgrep waybar &> /dev/null; then
        echo "  ✓ waybar"
    else
        echo "  ✗ waybar"
    fi
    
    if pgrep swaync &> /dev/null; then
        echo "  ✓ swaync"
    else
        echo "  ✗ swaync"
    fi
    echo ""
    
    echo "Log file: ${LOG_FILE}"
}

# Parse arguments
MODE="full"

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--full)
            MODE="full"
            shift
            ;;
        -q|--quick)
            MODE="quick"
            shift
            ;;
        -s|--services)
            MODE="services"
            shift
            ;;
        -c|--check)
            MODE="check"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Execute based on mode
case "$MODE" in
    full)
        init_full
        ;;
    quick)
        init_quick
        ;;
    services)
        init_services
        ;;
    check)
        check_status
        ;;
esac
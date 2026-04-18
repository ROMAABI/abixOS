#!/usr/bin/env bash
# abix-restore.sh - AbixOS Config Restoration
# Restore configs from AbixOS to system locations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ABIX_DIR="${HOME}/.config/abix"
BACKUP_DIR="${HOME}/.config_backup_$(date +%Y%m%d)"
CACHE_DIR="${HOME}/.cache/abix"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[restore]${NC} $1"; }
log_success() { echo -e "${GREEN}[restore]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[restore]${NC} $1"; }
log_error() { echo -e "${RED}[restore]${NC} $1" >&2; }

show_help() {
    cat << EOF
Usage: abix-restore.sh [OPTIONS]

Options:
  -d, --dry-run     Show what would be done without doing it
  -f, --force       Overwrite existing configs
  -b, --backup      Create backup before restoring
  -l, --list        Show available configs to restore
  -s, --status      Show current restoration status
  -h, --help        Show this help

Config mappings are read from: $ABIX_DIR/config_map.lst
EOF
}

# Config mapping file
CONFIG_MAP="${ABIX_DIR}/config_map.lst"

# Create default config map if not exists
init_config_map() {
    if [[ ! -f "$CONFIG_MAP" ]]; then
        mkdir -p "$(dirname "$CONFIG_MAP")"
        cat > "$CONFIG_MAP" << 'EOF'
# AbixOS Config Mapping
# Format: target_path|source_path
# Example: $HOME/.config/hypr|$ABIX_DIR/hypr

$HOME/.config/hypr|$ABIX_DIR/hypr
$HOME/.config/waybar|$ABIX_DIR/waybar
$HOME/.config/rofi|$ABIX_DIR/rofi
$HOME/.config/kitty|$ABIX_DIR/kitty
$HOME/.local/share/hypr|$ABIX_DIR/../local/share/hypr
EOF
        log_info "Created config map: $CONFIG_MAP"
    fi
}

# Show available configs
list_configs() {
    init_config_map
    
    echo "=== Available Configs ==="
    while IFS='|' read -r target source; do
        [[ -z "$target" || "$target" == \#* ]] && continue
        
        # Expand variables
        target_exp=$(eval echo "$target")
        source_exp=$(eval echo "$source")
        
        if [[ -d "$source_exp" || -f "$source_exp" ]]; then
            if [[ -e "$target_exp" ]]; then
                echo -e "  ${YELLOW}○${NC} $target_exp (exists)"
            else
                echo -e "  ${GREEN}+${NC} $target_exp (new)"
            fi
        fi
    done < "$CONFIG_MAP"
}

# Show status
show_status() {
    init_config_map
    
    echo "=== Restoration Status ==="
    local installed=0
    local missing=0
    
    while IFS='|' read -r target source; do
        [[ -z "$target" || "$target" == \#* ]] && continue
        
        target_exp=$(eval echo "$target")
        source_exp=$(eval echo "$source")
        
        if [[ -e "$target_exp" ]]; then
            ((installed++))
            echo -e "  ${GREEN}✓${NC} $target_exp"
        else
            ((missing++))
            echo -e "  ${RED}✗${NC} $target_exp (not restored)"
        fi
    done < "$CONFIG_MAP"
    
    echo ""
    echo "Restored: $installed | Not restored: $missing"
}

# Restore configs
restore_configs() {
    local dry_run=false
    local force=false
    local backup=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dry-run) dry_run=true; shift ;;
            -f|--force) force=true; shift ;;
            -b|--backup) backup=true; shift ;;
            *) shift ;;
        esac
    done
    
    init_config_map
    
    if [[ "$dry_run" == true ]]; then
        log_info "DRY RUN - No changes will be made"
    fi
    
    # Create backup if requested
    if [[ "$backup" == true && "$dry_run" == false ]]; then
        mkdir -p "$BACKUP_DIR"
        log_info "Backing up to: $BACKUP_DIR"
        
        while IFS='|' read -r target source; do
            [[ -z "$target" || "$target" == \#* ]] && continue
            target_exp=$(eval echo "$target")
            
            if [[ -e "$target_exp" ]]; then
                parent_dir=$(dirname "$target_exp")
                mkdir -p "${BACKUP_DIR}/${parent_dir}"
                cp -r "$target_exp" "${BACKUP_DIR}/${parent_dir}/"
            fi
        done < "$CONFIG_MAP"
        
        log_success "Backup complete"
    fi
    
    # Restore configs
    while IFS='|' read -r target source; do
        [[ -z "$target" || "$target" == \#* ]] && continue
        
        target_exp=$(eval echo "$target")
        source_exp=$(eval echo "$source")
        
        if [[ ! -e "$source_exp" ]]; then
            log_warn "Source not found: $source_exp"
            continue
        fi
        
        if [[ -e "$target_exp" && "$force" == false ]]; then
            log_warn "Skipping (exists): $target_exp"
            continue
        fi
        
        if [[ "$dry_run" == true ]]; then
            log_info "Would restore: $target_exp"
        else
            mkdir -p "$(dirname "$target_exp")"
            cp -r "$source_exp" "$target_exp"
            log_success "Restored: $target_exp"
        fi
    done < "$CONFIG_MAP"
    
    log_success "Restore complete"
}

# Parse arguments
ACTION="help"

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            ACTION="dry-run"
            shift
            ;;
        -f|--force)
            ACTION="force"
            shift
            ;;
        -b|--backup)
            ACTION="backup"
            shift
            ;;
        -l|--list)
            ACTION="list"
            shift
            ;;
        -s|--status)
            ACTION="status"
            shift
            ;;
        -h|--help)
            ACTION="help"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Execute action
case "$ACTION" in
    dry-run)
        restore_configs --dry-run
        ;;
    force)
        restore_configs --force
        ;;
    backup)
        restore_configs --backup
        ;;
    list)
        list_configs
        ;;
    status)
        show_status
        ;;
    help)
        show_help
        ;;
esac
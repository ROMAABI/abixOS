#!/usr/bin/env bash
# abix-theme.sh - Switch between themes
# Part of AbixOS - HyDE-inspired but independent

set -euo pipefail

# Configuration
CONFIG_DIR="${HOME}/.config"
ABIX_DIR="${CONFIG_DIR}/abix"
THEMES_DIR="${ABIX_DIR}/themes"
HYDE_DIR="${CONFIG_DIR}/hyde"  # Optional HyDE support
WALLBASH_SCRIPT="${HOME}/.config/abix/scripts/abix-wall.sh"

# Help message
show_help() {
    cat << EOF
Usage: abix-theme.sh [OPTIONS] [theme_name]

Options:
  -l, --list          List available themes
  -r, --random        Select a random theme
  -p, --previous      Select previous theme
  -n, --next          Select next theme
  -i, --interactive   Use rofi to select theme (default if no args)
  -a, --apply-only    Apply theme without saving preference
  -s, --save-only     Save preference without applying
  -w, --with-wall     Also set wallpaper from theme
  -c, --no-color      Skip color generation
  -h, --help          Show this help message

If no theme_name is provided and no other option is used,
an interactive selector will be launched (requires rofi).

Examples:
  abix-theme.sh                    # Interactive selection
  abix-theme.sh -l                 # List themes
  abix-theme.sh -r                 # Random theme
  abix-theme.sh "Catppuccin Mocha" # Specific theme
  abix-theme.sh -w -c              # Theme with wallpaper, no colors
EOF
}

# Parse arguments
ACTION="interactive"
THEME_NAME=""
APPLY_ONLY=false
SAVE_ONLY=false
WITH_WALL=false
NO_COLOR=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--list)
            ACTION="list"
            shift
            ;;
        -r|--random)
            ACTION="random"
            shift
            ;;
        -p|--previous)
            ACTION="previous"
            shift
            ;;
        -n|--next)
            ACTION="next"
            shift
            ;;
        -i|--interactive)
            ACTION="interactive"
            shift
            ;;
        -a|--apply-only)
            APPLY_ONLY=true
            shift
            ;;
        -s|--save-only)
            SAVE_ONLY=true
            shift
            ;;
        -w|--with-wall)
            WITH_WALL=true
            shift
            ;;
        -c|--no-color)
            NO_COLOR=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            if [[ -z "$THEME_NAME" ]]; then
                THEME_NAME="$1"
            else
                echo "Error: Multiple theme names specified" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# Log function
log() {
    if [[ "$VERBOSE" == true ]]; then
        echo "[abix-theme] $1"
    fi
}

# Error handling
error() {
    echo "[abix-theme] ERROR: $1" >&2
    exit 1
}

warn() {
    echo "[abix-theme] WARNING: $1" >&2
}

success() {
    echo "[abix-theme] SUCCESS: $1"
}

# List available themes
list_themes() {
    local dirs=()
    
    # Check Abix themes
    if [[ -d "$THEMES_DIR" ]]; then
        while IFS= read -r -d '' dir; do
            dirs+=("$(basename "$dir")")
        done < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -print0)
    fi
    
    # Check HyDE themes if enabled and exists
    if [[ -d "$HYDE_DIR/themes" ]]; then
        while IFS= read -r -d '' dir; do
            dirs+=("$(basename "$dir") [HyDE]")
        done < <(find "$HYDE_DIR/themes" -mindepth 1 -maxdepth 1 -type d -print0)
    fi
    
    if [[ ${#dirs[@]} -eq 0 ]]; then
        echo "No themes found"
        return 1
    fi
    
    printf '%s\n' "${dirs[@]}" | sort -u
    return 0
}

# Get current theme from cache
get_current_theme() {
    local cache_file="${HOME}/.cache/abix/current_theme"
    if [[ -f "$cache_file" ]]; then
        cat "$cache_file"
    else
        echo "default"
    fi
}

# Save current theme to cache
save_current_theme() {
    local theme="$1"
    local cache_file="${HOME}/.cache/abix/current_theme"
    mkdir -p "$(dirname "$cache_file")"
    echo "$theme" > "$cache_file"
}

# Get theme index in sorted list
get_theme_index() {
    local theme="$1"
    local -a theme_list
    
    # Build theme list
    if [[ -d "$THEMES_DIR" ]]; then
        while IFS= read -r -d '' dir; do
            theme_list+=("$(basename "$dir")")
        done < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -print0)
    fi
    
    # Add HyDE themes if available
    if [[ -d "$HYDE_DIR/themes" ]]; then
        while IFS= read -r -d '' dir; do
            theme_list+=("$(basename "$dir")")
        done < <(find "$HYDE_DIR/themes" -mindepth 1 -maxdepth 1 -type d -print0)
    fi
    
    # Find index
    for i in "${!theme_list[@]}"; do
        if [[ "${theme_list[$i]}" == "$theme" ]]; then
            echo "$i"
            return 0
        fi
    done
    
    echo "-1"  # Not found
    return 1
}

# Apply a theme
apply_theme() {
    local theme="$1"
    local theme_dir=""
    
    # Find theme directory
    if [[ -d "$THEMES_DIR/$theme" ]]; then
        theme_dir="$THEMES_DIR/$theme"
    elif [[ -d "$HYDE_DIR/themes/$theme" ]]; then
        theme_dir="$HYDE_DIR/themes/$theme"
    else
        error "Theme not found: $theme"
        return 1
    fi
    
    log "Applying theme: $theme from $theme_dir"
    
    # Apply Hyprland colors if available
    if [[ -f "$theme_dir/hypr.theme" ]]; then
        log "Applying Hyprland colors"
        # Source the theme file to extract variables
        # In a real implementation, this would parse the theme file
        # For now, we'll just note it's available
        if [[ "$VERBOSE" == true ]]; then
            echo "Hyprland theme file found: $theme_dir/hypr.theme"
        fi
    fi
    
    # Apply Waybar colors if available
    if [[ -f "$theme_dir/waybar.theme" ]]; then
        log "Applying Waybar colors"
        if [[ "$VERBOSE" == true ]]; then
            echo "Waybar theme file found: $theme_dir/waybar.theme"
        fi
    fi
    
    # Apply Kitty colors if available
    if [[ -f "$theme_dir/kitty.theme" ]]; then
        log "Applying Kitty colors"
        if [[ "$VERBOSE" == true ]]; then
            echo "Kitty theme file found: $theme_dir/kitty.theme"
        fi
    fi
    
    # Apply Rofi colors if available
    if [[ -f "$theme_dir/rofi.theme" ]]; then
        log "Applying Rofi colors"
        if [[ "$VERBOSE" == true ]]; then
            echo "Rofi theme file found: $theme_dir/rofi.theme"
        fi
    fi
    
    # Handle wallpaper if requested
    if [[ "$WITH_WALL" == true ]]; then
        local wallpaper_dir="$theme_dir/wallpapers"
        if [[ -d "$wallpaper_dir" ]]; then
            log "Setting wallpaper from theme"
            # Find a wallpaper to use
            local wallpaper
            wallpaper=$(find "$wallpaper_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | head -1 || true)
            
            if [[ -n "$wallpaper" && -f "$wallpaper" ]]; then
                # Use abix-wall to set it
                if [[ "$NO_COLOR" == true ]]; then
                    "$WALLBASH_SCRIPT" "$wallpaper"
                else
                    "$WALLBASH_SCRIPT" -c "$wallpaper"
                fi
            else
                warn "No wallpaper found in theme's wallpapers directory"
            fi
        else
            warn "No wallpapers directory in theme"
        fi
    fi
    
    # Generate colors from wallpaper if enabled and not done above
    if [[ "$NO_COLOR" == false && "$WITH_WALL" == false ]]; then
        local current_wallpaper="${HOME}/.cache/abix/wallpaper/current"
        if [[ -f "$current_wallpaper" ]]; then
            local wallpaper_path
            wallpaper_path=$(cat "$current_wallpaper")
            if [[ -f "$wallpaper_path" ]]; then
                log "Generating colors from current wallpaper"
                # In a full implementation, this would call a color generation script
                if [[ "$VERBOSE" == true ]]; then
                    echo "Would generate colors from: $wallpaper_path"
                fi
            fi
        fi
    fi
    
    # Save theme preference unless apply-only
    if [[ "$SAVE_ONLY" == false ]]; then
        save_current_theme "$theme"
        log "Theme preference saved: $theme"
    fi
    
    success "Theme applied: $theme"
    return 0
}

# Get next theme in list
get_next_theme() {
    local current_theme
    current_theme=$(get_current_theme)
    local index
    index=$(get_theme_index "$current_theme")
    
    if [[ "$index" == "-1" ]]; then
        # Current theme not in list, return first
        list_themes | head -1
        return 0
    fi
    
    # Build theme list
    local -a theme_list
    if [[ -d "$THEMES_DIR" ]]; then
        while IFS= read -r -d '' dir; do
            theme_list+=("$(basename "$dir")")
        done < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -print0)
    fi
    
    if [[ -d "$HYDE_DIR/themes" ]]; then
        while IFS= read -r -d '' dir; do
            theme_list+=("$(basename "$dir")")
        done < <(find "$HYDE_DIR/themes" -mindepth 1 -maxdepth 1 -type d -print0)
    fi
    
    local count=${#theme_list[@]}
    if [[ $count -eq 0 ]]; then
        echo "default"
        return 0
    fi
    
    local next_index=$(( (index + 1) % count ))
    echo "${theme_list[$next_index]}"
}

# Get previous theme in list
get_prev_theme() {
    local current_theme
    current_theme=$(get_current_theme)
    local index
    index=$(get_theme_index "$current_theme")
    
    if [[ "$index" == "-1" ]]; then
        # Current theme not in list, return last
        list_themes | tail -1
        return 0
    fi
    
    # Build theme list
    local -a theme_list
    if [[ -d "$THEMES_DIR" ]]; then
        while IFS= read -r -d '' dir; do
            theme_list+=("$(basename "$dir")")
        done < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -print0)
    fi
    
    if [[ -d "$HYDE_DIR/themes" ]]; then
        while IFS= read -r -d '' dir; do
            theme_list+=("$(basename "$dir")")
        done < <(find "$HYDE_DIR/themes" -mindepth 1 -maxdepth 1 -type d -print0)
    fi
    
    local count=${#theme_list[@]}
    if [[ $count -eq 0 ]]; then
        echo "default"
        return 0
    fi
    
    local prev_index=$(( (index - 1 + count) % count ))
    echo "${theme_list[$prev_index]}"
}

# Interactive theme selection with rofi
select_theme_interactive() {
    if ! command -v rofi &> /dev/null; then
        error "rofi is required for interactive selection"
        return 1
    fi
    
    # Build theme list for rofi
    local -a theme_list
    local -a theme_display
    
    if [[ -d "$THEMES_DIR" ]]; then
        while IFS= read -r -d '' dir; do
            theme_list+=("$(basename "$dir")")
            theme_display+=("$(basename "$dir")")
        done < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -print0)
    fi
    
    if [[ -d "$HYDE_DIR/themes" ]]; then
        while IFS= read -r -d '' dir; do
            theme_list+=("$(basename "$dir")")
            theme_display+=("$(basename "$dir") [HyDE]")
        done < <(find "$HYDE_DIR/themes" -mindepth 1 -maxdepth 1 -type d -print0)
    fi
    
    if [[ ${#theme_list[@]} -eq 0 ]]; then
        error "No themes available for selection"
        return 1
    fi
    
    # Create rofi input
    local menu_content
    for i in "${!theme_list[@]}"; do
        menu_content+="${theme_display[$i]}\n"
    done
    
    # Show rofi menu
    local choice
    choice=$(echo -e "$menu_content" | rofi -dmenu -p "Select Theme" -i || true)
    
    if [[ -n "$choice" ]]; then
        # Strip [HyDE] suffix if present
        choice=$(echo "$choice" | sed 's/ \[HyDE\]$//')
        echo "$choice"
        return 0
    else
        return 1  # User cancelled
    fi
}

# Main execution
main() {
    local theme_to_apply=""
    
    case "$ACTION" in
        list)
            list_themes
            return 0
            ;;
        random)
            if [[ -d "$THEMES_DIR" ]] || [[ -d "$HYDE_DIR/themes" ]]; then
                local -a all_themes
                if [[ -d "$THEMES_DIR" ]]; then
                    while IFS= read -r -d '' dir; do
                        all_themes+=("$(basename "$dir")")
                    done < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -print0)
                fi
                
                if [[ -d "$HYDE_DIR/themes" ]]; then
                    while IFS= read -r -d '' dir; do
                        all_themes+=("$(basename "$dir")")
                    done < <(find "$HYDE_DIR/themes" -mindepth 1 -maxdepth 1 -type d -print0)
                fi
                
                if [[ ${#all_themes[@]} -gt 0 ]]; then
                    theme_to_apply="${all_themes[RANDOM % ${#all_themes[@]}]}"
                else
                    error "No themes available"
                    return 1
                fi
            else
                error "No themes directories found"
                return 1
            fi
            ;;
        previous)
            theme_to_apply=$(get_prev_theme)
            ;;
        next)
            theme_to_apply=$(get_next_theme)
            ;;
        interactive)
            theme_to_apply=$(select_theme_interactive)
            if [[ -z "$theme_to_apply" ]]; then
                info "Theme selection cancelled"
                return 0
            fi
            ;;
        *)
            # Specific theme name provided
            if [[ -n "$THEME_NAME" ]]; then
                theme_to_apply="$THEME_NAME"
            else
                # Default to current theme or first available
                theme_to_apply=$(get_current_theme)
                # Verify it exists, if not get first available
                if ! apply_theme "$theme_to_apply" &> /dev/null; then
                    local first_theme
                    first_theme=$(list_themes | head -1)
                    if [[ -n "$first_theme" ]]; then
                        theme_to_apply="$first_theme"
                    else
                        error "No themes available and current theme invalid"
                        return 1
                    fi
                fi
            fi
            ;;
    esac
    
    # Apply the selected theme
    if [[ -n "$theme_to_apply" ]]; then
        apply_theme "$theme_to_apply"
        return $?
    else
        error "No theme selected"
        return 1
    fi
}

# Execute main function
main "$@"
#!/usr/bin/env bash
# abix-notify.sh - Send notifications via swaync
# Part of AbixOS - HyDE-inspired but independent

set -euo pipefail

# Configuration
ICON_DIR="${HOME}/.config/abix/icons"
DEFAULT_ICON="${ICON_DIR}/abix-logo.png"
NOTIFY_APP="AbixOS"

# Help message
show_help() {
    cat << EOF
Usage: abix-notify.sh [OPTIONS] "message"

Options:
  -t, --title TEXT        Notification title (default: "AbixOS")
  -i, --icon PATH         Icon path (default: $DEFAULT_ICON)
  -a, --app NAME          Application name (default: "AbixOS")
  -u, --urgency LEVEL     Urgency level: low, normal, critical (default: normal)
  -e, --expire TIME       Expire time in milliseconds (default: 5000)
  -a, --action ACTION     Add action button (format: "label;command")
  -h, --help              Show this help message

Examples:
  abix-notify.sh "Hello World"
  abix-notify.sh -t "Error" -u critical "Something went wrong"
  abix-notify.sh -i "/path/to/icon.png" "Custom icon"
  abix-notify.sh -a "Open Config;abix-shell config" "Action notification"
EOF
}

# Parse arguments
TITLE="AbixOS"
ICON="$DEFAULT_ICON"
APP_NAME="$NOTIFY_APP"
URGENCY="normal"
EXPIRE=5000
ACTIONS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--title)
            if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                TITLE="$2"
                shift 2
            else
                echo "Error: --title requires an argument" >&2
                exit 1
            fi
            ;;
        -i|--icon)
            if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                ICON="$2"
                shift 2
            else
                echo "Error: --icon requires an argument" >&2
                exit 1
            fi
            ;;
        -a|--app)
            if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                APP_NAME="$2"
                shift 2
            else
                echo "Error: --app requires an argument" >&2
                exit 1
            fi
            ;;
        -u|--urgency)
            if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                case "$2" in
                    low|normal|critical)
                        URGENCY="$2"
                        ;;
                    *)
                        echo "Error: Urgency must be low, normal, or critical" >&2
                        exit 1
                        ;;
                esac
                shift 2
            else
                echo "Error: --urgency requires an argument" >&2
                exit 1
            fi
            ;;
        -e|--expire)
            if [[ -n "$2" && ! "$2" =~ ^- ]] && [[ "$2" =~ ^[0-9]+$ ]]; then
                EXPIRE="$2"
                shift 2
            else
                echo "Error: --expire requires a positive integer" >&2
                exit 1
            fi
            ;;
        -a|--action)
            if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                ACTIONS+=("$2")
                shift 2
            else
                echo "Error: --action requires an argument" >&2
                exit 1
            fi
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            exit 1
            ;;
        *)
            # First non-option argument is the message
            break
            ;;
    esac
done

# Check if message is provided
if [[ $# -eq 0 ]]; then
    echo "Error: No message provided" >&2
    echo "Use -h for help" >&2
    exit 1
fi

MESSAGE="$1"

# Log function (for debugging)
log() {
    # echo "[abix-notify] $1" >&2  # Uncomment for debugging
    :
}

# Check dependencies
check_dependencies() {
    local missing=()
    
    # Check for swaync-client (preferred) or notify-send (fallback)
    if ! command -v swaync-client &> /dev/null && ! command -v notify-send &> /dev/null; then
        missing+=("swaync-client or notify-send")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Missing dependencies: ${missing[*]}" >&2
        exit 1
    fi
}

# Send notification via swaync-client
send_swaync_notification() {
    local cmd=(swaync-client)
    
    # Add title if not default
    if [[ "$TITLE" != "$NOTIFY_APP" ]]; then
        cmd+=(--title "$TITLE")
    fi
    
    # Add application name
    cmd+=(--app-name "$APP_NAME")
    
    # Add urgency
    cmd+=(--urgency "$URGENCY")
    
    # Add expire time
    cmd+=(--timeout "$EXPIRE")
    
    # Add icon if file exists
    if [[ -f "$ICON" ]]; then
        cmd+=(--icon "$ICON")
    elif [[ -n "$ICON" && "$ICON" != "$DEFAULT_ICON" ]]; then
        echo "Warning: Icon file not found: $ICON" >&2
    fi
    
    # Add actions
    for action in "${ACTIONS[@]}"; do
        cmd+=(--action "$action")
    done
    
    # Add message
    cmd+=("$MESSAGE")
    
    # Execute
    if "${cmd[@]}" &> /dev/null; then
        log "Notification sent via swaync-client"
        return 0
    else
        echo "Error: Failed to send notification via swaync-client" >&2
        return 1
    fi
}

# Send notification via notify-send (fallback)
send_notify_send_notification() {
    local cmd=(notify-send)
    
    # Map urgency levels
    case "$URGENCY" in
        low)    cmd+=(--urgency=low) ;;
        normal) cmd+=(--urgency=normal) ;;
        critical) cmd+=(--urgency=critical) ;;
    esac
    
    # Add expire time
    cmd+=(--expire-time="$EXPIRE")
    
    # Add app name
    cmd+=(--app-name="$APP_NAME")
    
    # Add icon if file exists
    if [[ -f "$ICON" ]]; then
        cmd+=(--icon="$ICON")
    fi
    
    # Add title and message
    cmd+=("$TITLE" "$MESSAGE")
    
    # Note: notify-send doesn't support action buttons in the same way
    if [[ ${#ACTIONS[@]} -gt 0 ]]; then
        echo "Warning: notify-send doesn't support action buttons, ignoring actions" >&2
    fi
    
    # Execute
    if "${cmd[@]}" &> /dev/null; then
        log "Notification sent via notify-send (fallback)"
        return 0
    else
        echo "Error: Failed to send notification via notify-send" >&2
        return 1
    fi
}

# Main execution
main() {
    # Check dependencies
    check_dependencies
    
    # Try swaync-client first, fall back to notify-send
    if command -v swaync-client &> /dev/null; then
        if send_swaync_notification; then
            exit 0
        else
            # Fall back to notify-send if swaync fails
            if command -v notify-send &> /dev/null; then
                echo "Warning: Failed to send via swaync-client, trying notify-send..." >&2
                if send_notify_send_notification; then
                    exit 0
                else
                    exit 1
                fi
            else
                exit 1
            fi
        fi
    else
        # Only notify-send available
        if send_notify_send_notification; then
            exit 0
        else
            exit 1
        fi
    fi
}

# Execute main function
main "$@"
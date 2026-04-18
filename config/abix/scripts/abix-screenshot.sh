#!/usr/bin/env bash
# abix-screenshot.sh - AbixOS Screenshot Utility

set -euo pipefail

SCREENSHOTS_DIR="${HOME}/Pictures/Screenshots"
CACHE_DIR="${HOME}/.cache/abix"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$SCREENSHOTS_DIR" "$CACHE_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    cat << EOF
Usage: abix-screenshot.sh [OPTIONS]

Options:
  -s, --screen      Screenshot entire screen
  -w, --window      Screenshot active window
  -r, --region      Screenshot region (selection)
  -c, --clipboard   Copy to clipboard instead of saving
  -d, --delay SEC   Delay before screenshot
  -o, --open        Open after taking
  -h, --help        Show this help

Default: Screenshot entire screen and save to $SCREENSHOTS_DIR
EOF
}

# Parse arguments
MODE="screen"
CLIPBOARD=false
DELAY=0
OPEN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--screen)
            MODE="screen"
            shift
            ;;
        -w|--window)
            MODE="window"
            shift
            ;;
        -r|--region)
            MODE="region"
            shift
            ;;
        -c|--clipboard)
            CLIPBOARD=true
            shift
            ;;
        -d|--delay)
            DELAY="${2:-1}"
            shift 2
            ;;
        -o|--open)
            OPEN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Check dependencies
if ! command -v grim &>/dev/null; then
    echo -e "${RED}Error: grim is required. Install with: sudo pacman -S grim${NC}" >&2
    exit 1
fi

# Optional: slurp for region/window
if [[ "$MODE" == "region" ]] && ! command -v slurp &>/dev/null; then
    echo -e "${YELLOW}Warning: slurp not found. Install for region selection: sudo pacman -S slurp${NC}" >&2
    MODE="screen"
fi

# Delay if specified
if [[ $DELAY -gt 0 ]]; then
    sleep "$DELAY"
fi

# Take screenshot
OUTPUT_FILE="${SCREENSHOTS_DIR}/screenshot_${TIMESTAMP}.png"

case "$MODE" in
    screen)
        grim "$OUTPUT_FILE"
        ;;
    window)
        grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" "$OUTPUT_FILE" 2>/dev/null || \
        grim "$OUTPUT_FILE"
        ;;
    region)
        grim -s "$(slurp)" "$OUTPUT_FILE"
        ;;
esac

# Copy to clipboard if requested
if [[ "$CLIPBOARD" == true ]]; then
    if command -v wl-copy &>/dev/null; then
        wl-copy < "$OUTPUT_FILE"
        echo -e "${GREEN}Screenshot copied to clipboard${NC}"
    elif command -v xclip &>/dev/null; then
        xclip -selection clipboard -t image/png < "$OUTPUT_FILE"
        echo -e "${GREEN}Screenshot copied to clipboard${NC}"
    else
        echo -e "${YELLOW}Warning: No clipboard tool found${NC}"
    fi
fi

# Open if requested
if [[ "$OPEN" == true ]]; then
    if command -v imv &>/dev/null; then
        imv "$OUTPUT_FILE" &
    elif command -v feh &>/dev/null; then
        feh "$OUTPUT_FILE" &
    fi
fi

echo -e "${GREEN}Screenshot saved:${NC} $OUTPUT_FILE"

# Store last screenshot path
echo "$OUTPUT_FILE" > "${CACHE_DIR}/last_screenshot"
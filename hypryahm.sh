#!/usr/bin/env bash

# hypryahm.sh - Manage wallpapers with hyprpaper
# Features: Cycle forward/backward, random, specify directory/image

# Common wallpaper directories
SEARCH_DIRS=(
    "$HOME/Wallpapers"
    "$HOME/Pictures/Wallpapers"
    "$HOME/Pictures/wallpaper"
    "$HOME/.config/wallpapers"
)

STATE_FILE="$HOME/.cache/hypryahm_state"
WALLPAPER_DIR=""
FIT_MODE=""

# Ensure cache directory exists
mkdir -p "$(dirname "$STATE_FILE")"

show_help() {
    echo "Usage: $(basename "$0") [options]"
    echo "Options:"
    echo "  -n          Cycle next wallpaper"
    echo "  -p          Cycle previous wallpaper"
    echo "  -r          Random wallpaper"
    echo "  -w <dir>    Specify wallpaper directory"
    echo "  -i <file>   Set specific image"
    echo "  -m <mode>   Fit mode: fill, tile, cover, contain (default: fill)"
    echo "  -h          Show help"
    echo ""
    echo "Default search locations:"
    for dir in "${SEARCH_DIRS[@]}"; do echo "  $dir"; done
}

find_wallpaper_dir() {
    if [[ -n "$WALLPAPER_DIR" ]]; then
        if [[ -d "$WALLPAPER_DIR" ]]; then
            return 0
        else
            echo "Error: Directory '$WALLPAPER_DIR' not found." >&2
            exit 1
        fi
    fi

    for dir in "${SEARCH_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            WALLPAPER_DIR="$dir"
            return 0
        fi
    done

    echo "Error: Could not find a wallpaper directory." >&2
    echo "Please specify one with -w <path/to/dir>" >&2
    exit 1
}

get_images() {
    local dir="$1"
    # Supported extensions
    find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort
}

set_wallpaper() {
    local img="$1"

    if [[ ! -f "$img" ]]; then
        echo "Error: File '$img' does not exist." >&2
        return 1
    fi

    # Convert to absolute path if not already
    img=$(realpath "$img")

    # Validate fit mode
    local mode="${FIT_MODE:-fill}"
    case "$mode" in
        fill|tile|cover|contain) ;;
        *)
            echo "Error: Invalid fit mode '$mode'. Use fill, tile, cover, or contain." >&2
            return 1
            ;;
    esac

    # Check if hyprpaper is running
    if ! pgrep -x "hyprpaper" > /dev/null; then
        echo "Warning: hyprpaper is not running. Starting it..."
        hyprpaper &
        sleep 1
    fi

    # Get active monitors
    local monitors
    if command -v jq >/dev/null 2>&1; then
        monitors=$(hyprctl monitors -j | jq -r '.[].name')
    else
        monitors=$(hyprctl monitors | grep "Monitor" | awk '{print $2}')
    fi

    if [[ -z "$monitors" ]]; then
        echo "Error: No active monitors found via hyprctl." >&2
        return 1
    fi

    echo "Setting wallpaper: $img (mode: $mode)"

    # Set wallpaper on each monitor using [mon],[path],[fit_mode] format
    for m in $monitors; do
        hyprctl hyprpaper wallpaper "$m,$img,$mode"
    done

    # Save state
    echo "$img" > "$STATE_FILE"
}

ACTION=""
SPECIFIC_VAL=""

while getopts "nprw:i:m:h" opt; do
    case "$opt" in
        n) ACTION="next" ;;
        p) ACTION="prev" ;;
        r) ACTION="random" ;;
        w) WALLPAPER_DIR="$OPTARG" ;;
        i) ACTION="image"; SPECIFIC_VAL="$OPTARG" ;;
        m) FIT_MODE="$OPTARG" ;;
        h) show_help; exit 0 ;;
        *) show_help; exit 1 ;;
    esac
done

# Default to help if no action
if [[ -z "$ACTION" && -z "$WALLPAPER_DIR" ]]; then
    show_help
    exit 1
fi

# Set specific image handle
if [[ "$ACTION" == "image" ]]; then
    set_wallpaper "$SPECIFIC_VAL"
    exit 0
fi

# Find or validate directory
find_wallpaper_dir

# Get list of images
IFS=$'\n' IMAGES=($(get_images "$WALLPAPER_DIR"))
unset IFS

if [[ ${#IMAGES[@]} -eq 0 ]]; then
    echo "Error: No images found in $WALLPAPER_DIR" >&2
    exit 1
fi

# Determine current index
CURRENT_WALL=$(cat "$STATE_FILE" 2>/dev/null)
INDEX=-1

for i in "${!IMAGES[@]}"; do
    if [[ "${IMAGES[$i]}" == "$CURRENT_WALL" ]]; then
        INDEX=$i
        break
    fi
done

# Perform action
case "$ACTION" in
    next)
        INDEX=$(( (INDEX + 1) % ${#IMAGES[@]} ))
        ;;
    prev)
        # Use + size for modulo with negative numbers
        INDEX=$(( (INDEX - 1 + ${#IMAGES[@]}) % ${#IMAGES[@]} ))
        ;;
    random)
        INDEX=$(( RANDOM % ${#IMAGES[@]} ))
        ;;
    *)
        # If no action but dir was specified, maybe just pick first or random?
        # Let's pick random if no other instruction given but dir provided
        INDEX=$(( RANDOM % ${#IMAGES[@]} ))
        ;;
esac

set_wallpaper "${IMAGES[$INDEX]}"

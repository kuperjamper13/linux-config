#!/bin/bash

# ==============================================================================
# 💎 AESTHETIC CONFIGURATION (NEON TERMINAL THEME)
# ==============================================================================
# Reset
NC='\033[0m'

# Palette
BOLD='\033[1m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
WHITE='\033[1;37m'
DIM='\033[2m'

# Icons
ICON_OK="[${GREEN}OK${NC}]"
ICON_ERR="[${RED}!!${NC}]"
ICON_ASK="[${MAGENTA}??${NC}]"
ICON_INF="[${CYAN}::${NC}]"
ICON_GIT="[${YELLOW}GIT${NC}]"

# Configuration
REPO_URL="https://github.com/kuperjamper13/linux-config.git"
LOCAL_REPO="$HOME/linux-config" # Standardizing folder name to repo name
CONFIG_DIR="$HOME/.config"

function draw_line {
    echo -e "${DIM}────────────────────────────────────────────────────────────${NC}"
}

function show_header {
    clear
    echo -e "${MAGENTA}"
    echo "  ██████  ██    ██  ███▄    █  ▄▄▄       "
    echo "▒██    ▒  ██    ██  ██ ▀█   █ ▒████▄     "
    echo "░ ▓██▄    █    █  ██  ▀█ ██ ▒██  ▀█▄   "
    echo "  ▒   ██▒ ▓██▄██▓  ██▒  ▐▌██ ░██▄▄▄▄██  "
    echo "▒██████▒▒  ▒██▒   ▒██░   ▓██ ░ ▓█   ▓██▒ "
    echo "▒ ▒▓▒ ▒ ░  ▒ ▒░   ░ ▒░   ▒ ▒   ▒▒   ▓▒█░ "
    echo "░ ░▒  ░ ░  ░ ░░   ░ ░░   ░ ▒░   ▒   ▒▒ ░ "
    echo "░  ░  ░      ░       ░   ░ ░    ░   ▒    "
    echo "      ░                          ░  ░    "
    echo -e "${NC}"
    echo -e "${CYAN}   // DOTFILES SYNC SYSTEM //${NC}"
    draw_line
}

function step_title {
    echo -e "\n${CYAN}┌──[ STEP $1/4 ] :: $2${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────${NC}"
}

show_header

# ==============================================================================
# 1. GIT SYNC
# ==============================================================================
step_title "1" "SYNCHRONIZING REPO"

# Check if we need to Clone or Pull
if [ -d "$LOCAL_REPO" ]; then
    echo -e "${ICON_GIT} Repo found at ${BOLD}$LOCAL_REPO${NC}"
    echo -e "${ICON_INF} Pulling latest changes..."
    cd "$LOCAL_REPO"
    
    # Stash local changes to prevent conflicts, pull, then apply stash
    git stash -q
    git pull origin main
    git stash pop -q &>/dev/null
    
    echo -e "${ICON_OK} Up to date."
else
    echo -e "${ICON_GIT} Repo not found. Cloning fresh..."
    git clone "$REPO_URL" "$LOCAL_REPO"
    if [ $? -ne 0 ]; then
        echo -e "${ICON_ERR} Clone failed. Check internet connection."
        exit 1
    fi
    echo -e "${ICON_OK} Cloned successfully."
fi

# Locate the actual config source (handling .dotfiles subfolder)
if [ -d "$LOCAL_REPO/.dotfiles" ]; then
    DOTFILES_SOURCE="$LOCAL_REPO/.dotfiles"
    echo -e "${ICON_INF} Using source: ${WHITE}$DOTFILES_SOURCE${NC}"
else
    DOTFILES_SOURCE="$LOCAL_REPO"
    echo -e "${ICON_INF} Using source: ${WHITE}$DOTFILES_SOURCE (Root)${NC}"
fi

# ==============================================================================
# 2. KEYMAP INJECTION
# ==============================================================================
step_title "2" "HARDWARE ADAPTATION"

# Detect System Keymap
DETECTED_KEYMAP=$(grep KEYMAP /etc/vconsole.conf | cut -d= -f2)
[[ -z "$DETECTED_KEYMAP" ]] && DETECTED_KEYMAP="us"

echo -e "${ICON_INF} System Keymap: ${BOLD}$DETECTED_KEYMAP${NC}"

# Inject into Hyprland Config
HYPR_CONF="$DOTFILES_SOURCE/hypr/hyprland.conf"

if [ -f "$HYPR_CONF" ]; then
    echo -e "${ICON_INF} Injecting keymap into local config copy..."
    # We use sed to replace standard US layout with the detected one
    sed -i "s/kb_layout = us/kb_layout = $DETECTED_KEYMAP/g" "$HYPR_CONF"
    sed -i "s/kb_layout = es/kb_layout = $DETECTED_KEYMAP/g" "$HYPR_CONF" # Safety check if source was already es
    echo -e "${ICON_OK} Keymap applied."
else
    echo -e "${ICON_ERR} Warning: hyprland.conf not found."
fi

# ==============================================================================
# 3. SYMLINK ENGINE
# ==============================================================================
step_title "3" "UPDATING LINKS"

mkdir -p "$CONFIG_DIR"

link_config() {
    TARGET=$1
    if [ -d "$DOTFILES_SOURCE/$TARGET" ]; then
        # Remove old link or folder (backup not needed for update script usually, but safe to force link)
        rm -rf "$CONFIG_DIR/$TARGET"
        ln -sf "$DOTFILES_SOURCE/$TARGET" "$CONFIG_DIR/$TARGET"
        echo -e "${ICON_OK} Linked: ${WHITE}$TARGET${NC}"
    else
        echo -e "${ICON_ERR} Missing in repo: $TARGET"
    fi
}

# List of modules to link
link_config "hypr"
link_config "waybar"
link_config "kitty"
link_config "rofi"

# ==============================================================================
# 4. REFRESH SYSTEM
# ==============================================================================
step_title "4" "RELOADING DESKTOP"

if pgrep -x "hyprland" > /dev/null; then
    echo -e "${ICON_INF} Reloading Hyprland..."
    hyprctl reload &>/dev/null
    
    echo -e "${ICON_INF} Reloading Waybar..."
    killall waybar &>/dev/null
    waybar &>/dev/null &
    
    echo -e "${ICON_OK} Dashboard Refreshed."
else
    echo -e "${ICON_INF} Hyprland not running. Skipping reload."
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}   UPDATE COMPLETE                      ${NC}"
echo -e "${GREEN}========================================${NC}"

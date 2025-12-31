#!/bin/bash

# ==============================================================================
# 💎 AESTHETIC CONFIGURATION
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
ICON_PKG="[${BLUE}PKG${NC}]"
ICON_SUDO="[${RED}ADMIN${NC}]"

# Configuration
REPO_URL="https://github.com/kuperjamper13/linux-config.git"
LOCAL_REPO="$HOME/linux-config"
CONFIG_DIR="$HOME/.config"

function step_title {
    echo -e "\n${CYAN}┌──[ STEP $1/6 ] :: $2${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────${NC}"
}

clear
echo -e "${MAGENTA}   // SYSTEM UPDATE & DOTFILES SYNC v3.2 //${NC}"

# ==============================================================================
# 1. SYSTEM MAINTENANCE
# ==============================================================================
step_title "1" "SYSTEM PACKAGES"

echo -e "${ICON_PKG} Updating Official Repos..."
sudo pacman -Syu --noconfirm

if command -v yay &> /dev/null; then
    echo -e "${ICON_PKG} Updating AUR..."
    yay -Syu --noconfirm
else
    echo -e "${ICON_INF} Yay not found. Skipping AUR."
fi

# ==============================================================================
# 2. GIT SYNC
# ==============================================================================
step_title "2" "REPO SYNC"

if [ -d "$LOCAL_REPO" ]; then
    echo -e "${ICON_GIT} Pulling changes at $LOCAL_REPO..."
    cd "$LOCAL_REPO"
    git stash -q
    git pull origin main
    git stash pop -q &>/dev/null
else
    echo -e "${ICON_GIT} Cloning fresh repo..."
    git clone "$REPO_URL" "$LOCAL_REPO"
fi

# Intelligent Source Detection
if [ -d "$LOCAL_REPO/.dotfiles" ]; then
    DOTFILES_SOURCE="$LOCAL_REPO/.dotfiles"
else
    DOTFILES_SOURCE="$LOCAL_REPO"
fi

# ==============================================================================
# 3. SDDM THEME ENGINE
# ==============================================================================
step_title "3" "LOGIN SCREEN (SDDM)"

echo -e "${ICON_INF} Installing 'Sugar Dark' theme..."
if ! pacman -Qs sddm-sugar-dark &> /dev/null; then
    yay -S --noconfirm sddm-sugar-dark
fi

echo -e "${ICON_SUDO} Applying SDDM Configuration..."
if [ -f "$DOTFILES_SOURCE/sddm/sddm.conf" ]; then
    sudo cp "$DOTFILES_SOURCE/sddm/sddm.conf" /etc/sddm.conf
    echo -e "${ICON_OK} Configuration applied to /etc/sddm.conf"
else
    echo -e "${ICON_ERR} No sddm.conf found in dotfiles."
fi

# ==============================================================================
# 4. KEYMAP INJECTION
# ==============================================================================
step_title "4" "HARDWARE ADAPTATION"

DETECTED_KEYMAP=$(grep KEYMAP /etc/vconsole.conf | cut -d= -f2)
[[ -z "$DETECTED_KEYMAP" ]] && DETECTED_KEYMAP="us"
echo -e "${ICON_INF} Keymap: ${BOLD}$DETECTED_KEYMAP${NC}"

HYPR_CONF="$DOTFILES_SOURCE/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
    sed -i "s/kb_layout = us/kb_layout = $DETECTED_KEYMAP/g" "$HYPR_CONF"
    sed -i "s/kb_layout = es/kb_layout = $DETECTED_KEYMAP/g" "$HYPR_CONF" 
    echo -e "${ICON_OK} Keymap injected."
fi

# ==============================================================================
# 5. USER CONFIG LINKS
# ==============================================================================
step_title "5" "USER DOTFILES"

mkdir -p "$CONFIG_DIR"

link_config() {
    TARGET=$1
    if [ -d "$DOTFILES_SOURCE/$TARGET" ]; then
        rm -rf "$CONFIG_DIR/$TARGET"
        ln -sf "$DOTFILES_SOURCE/$TARGET" "$CONFIG_DIR/$TARGET"
        echo -e "${ICON_OK} Linked: $TARGET"
    else
        echo -e "${ICON_ERR} Missing: $TARGET"
    fi
}

link_config "hypr"
link_config "waybar"
link_config "kitty"
link_config "rofi"

# ==============================================================================
# 6. LIVE RELOAD
# ==============================================================================
step_title "6" "HOT RELOAD & WALLPAPER"

# 1. Reload Hyprland
echo -e "${ICON_INF} Reloading Hyprland Config..."
hyprctl reload &>/dev/null

# 2. Reload Kitty
echo -e "${ICON_INF} Refreshing Kitty Terminals..."
pkill -USR1 kitty

# 3. Reload Waybar
echo -e "${ICON_INF} Restarting Waybar..."
pkill waybar
sleep 0.5 
if command -v waybar &> /dev/null; then
    waybar > /dev/null 2>&1 & disown
    echo -e "${ICON_OK} Waybar restarted."
fi

# 4. Reload Wallpaper (SWWW FIXED)
WALLPAPER_PATH="$DOTFILES_SOURCE/wallpaper.png"
echo -e "${ICON_INF} Applying Wallpaper: $WALLPAPER_PATH"

if [ -f "$WALLPAPER_PATH" ]; then
    
    # Check if swww is installed
    if ! command -v swww &> /dev/null; then
        echo -e "${ICON_PKG} swww not found. Installing..."
        yay -S --noconfirm swww
    fi

    # Check if swww-daemon is running
    # Note: New swww versions use 'swww-daemon', not 'swww init'
    if ! pgrep -x "swww-daemon" > /dev/null; then
        echo -e "${ICON_INF} swww daemon not running. Starting..."
        swww-daemon > /dev/null 2>&1 & disown
        sleep 1 # Wait for daemon to initialize socket
    fi

    # Apply wallpaper
    swww img "$WALLPAPER_PATH" --transition-type grow --transition-pos 0.5,0.5 --transition-fps 60
    echo -e "${ICON_OK} Wallpaper updated via swww."

else
    echo -e "${ICON_ERR} Wallpaper file not found at $WALLPAPER_PATH"
fi

echo -e "\n${GREEN}=== UPDATE COMPLETE & APPLIED ===${NC}"

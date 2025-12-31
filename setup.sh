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

function draw_line {
    echo -e "${DIM}────────────────────────────────────────────────────────────${NC}"
}

function show_header {
    clear
    echo -e "${MAGENTA}"
    echo "  ██████ ▓█████ ▄▄▄█████▓ █    ██  ██▓███  "
    echo "▒██    ▒ ▓█   ▀ ▓  ██▒ ▓▒ ██  ▓██▒▓██░  ██▒"
    echo "░ ▓██▄   ▒███   ▒ ▓██░ ▒░▓██  ▒██░▓██░ ██▓▒"
    echo "  ▒   ██▒▒▓█  ▄ ░ ▓██▓ ░ ▓▓█  ░██░▒██▄█▓▒ ▒"
    echo "▒██████▒▒░▒████▒  ▒██▒ ░ ▒▒█████▓ ▒██▒ ░  ░"
    echo "▒ ▒▓▒ ▒ ░░░ ▒░ ░  ▒ ░░   ░▒▓▒ ▒ ▒ ▒▓▒░ ░  ░"
    echo "░ ░▒  ░ ░ ░ ░  ░    ░    ░░▒░ ░ ░ ░▒ ░     "
    echo "░  ░  ░     ░     ░       ░░░ ░ ░ ░░       "
    echo "      ░     ░  ░            ░              "
    echo -e "${NC}"
    echo -e "${CYAN}   // GITHUB BOOTSTRAP SYSTEM v5.0 //${NC}"
    draw_line
}

function step_title {
    echo -e "\n${CYAN}┌──[ STEP $1/5 ] :: $2${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────${NC}"
}

show_header

# ==============================================================================
# 1. NETWORK CHECK
# ==============================================================================
step_title "1" "CONNECTIVITY CHECK"

if ping -c 1 google.com &> /dev/null; then
    echo -e "${ICON_OK} ${GREEN}Online.${NC}"
else
    echo -e "${ICON_ERR} ${YELLOW}Offline.${NC}"
    echo -e "Launching Network Manager UI..."
    read -p "Press Enter..."
    nmtui
fi

# ==============================================================================
# 2. AUR HELPER (YAY)
# ==============================================================================
step_title "2" "AUR HELPER (YAY)"

if ! command -v yay &> /dev/null; then
    echo -e "${ICON_INF} Installing yay..."
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    echo -e "${ICON_OK} yay is ready."
fi

# ==============================================================================
# 3. CORE PACKAGES
# ==============================================================================
step_title "3" "SYSTEM PACKAGES"
echo -e "${WHITE}Installing Graphics, Desktop, and Apps...${NC}"

PACKAGES=(
    nvidia-dkms nvidia-utils egl-wayland
    hyprland waybar dunst libnotify swww kitty rofi-wayland
    sddm
    ttf-jetbrains-mono-nerd noto-fonts-emoji ttf-fira-sans
    pipewire pipewire-pulse wireplumber
    thunar gvfs
)

sudo pacman -S --noconfirm "${PACKAGES[@]}"

# Apps
yay -S --noconfirm google-chrome visual-studio-code-bin

sudo systemctl enable sddm
sudo systemctl enable bluetooth

# ==============================================================================
# 4. DOTFILES CLONING
# ==============================================================================
step_title "4" "CLONING REPO"

REPO_DIR="$HOME/setup-repo"
CONFIG_DIR="$HOME/.config"

# Ask for Repo
echo -e "${WHITE}Enter the URL of your GitHub Project:${NC}"
echo -e "${DIM}(Example: https://github.com/YourName/arch-setup.git)${NC}"
read -p "$(echo -e "${ICON_ASK} Repo URL: ${NC}")" REPO_URL

if [ -d "$REPO_DIR" ]; then
    echo -e "${ICON_INF} Removing old setup repo..."
    rm -rf "$REPO_DIR"
fi

echo -e "${ICON_INF} Cloning..."
git clone "$REPO_URL" "$REPO_DIR"

if [ $? -ne 0 ]; then
    echo -e "${ICON_ERR} Git clone failed. Check URL."
    exit 1
fi

# INTELLIGENT PATH DETECTION
# If the repo has a ".dotfiles" folder, use it. Otherwise use repo root.
if [ -d "$REPO_DIR/.dotfiles" ]; then
    DOTFILES_SOURCE="$REPO_DIR/.dotfiles"
    echo -e "${ICON_OK} Found .dotfiles subfolder."
else
    DOTFILES_SOURCE="$REPO_DIR"
    echo -e "${ICON_INF} Using repository root as config source."
fi

# ==============================================================================
# 5. DYNAMIC CONFIG INJECTION & LINKING
# ==============================================================================
step_title "5" "APPLYING CONFIGS"

# --- A. DETECT & INJECT KEYMAP ---
DETECTED_KEYMAP=$(grep KEYMAP /etc/vconsole.conf | cut -d= -f2)
[[ -z "$DETECTED_KEYMAP" ]] && DETECTED_KEYMAP="us"

echo -e "${ICON_INF} Detected Keymap: ${BOLD}$DETECTED_KEYMAP${NC}"
echo -e "${ICON_INF} Injecting keymap into Hyprland config..."

# Use sed to replace 'kb_layout = us' with system keymap in the downloaded file
if [ -f "$DOTFILES_SOURCE/hypr/hyprland.conf" ]; then
    sed -i "s/kb_layout = us/kb_layout = $DETECTED_KEYMAP/g" "$DOTFILES_SOURCE/hypr/hyprland.conf"
else
    echo -e "${ICON_ERR} Warning: hyprland.conf not found in $DOTFILES_SOURCE/hypr/"
fi

# --- B. SYMLINK ENGINE ---
echo -e "${ICON_INF} Linking files from ${BOLD}$DOTFILES_SOURCE${NC}..."
mkdir -p "$CONFIG_DIR"

link_config() {
    # $1 = Folder Name (e.g. hypr)
    
    # Check if source exists in repo
    if [ -d "$DOTFILES_SOURCE/$1" ]; then
        # Backup existing config if it's not a link
        if [ -d "$CONFIG_DIR/$1" ] && [ ! -L "$CONFIG_DIR/$1" ]; then
            mv "$CONFIG_DIR/$1" "$CONFIG_DIR/$1.bak"
        fi
        
        # Create Symlink
        ln -sf "$DOTFILES_SOURCE/$1" "$CONFIG_DIR/$1"
        echo -e "   -> Linked $1"
    else
        echo -e "   ${ICON_ERR} Skipped $1 (Folder not found in repo)"
    fi
}

# Link specific folders
link_config "hypr"
link_config "kitty"
link_config "waybar"
link_config "rofi"  # <--- ADDED THIS

# --- C. NVIDIA GRUB FIX ---
echo -e "${ICON_INF} Applying Nvidia GRUB fix..."
if ! grep -q "nvidia_drm.modeset=1" /etc/default/grub; then
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia_drm.modeset=1 /' /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}   SYSTEM READY! REBOOTING...           ${NC}"
echo -e "${GREEN}========================================${NC}"
read -p "Press Enter to Reboot..."
sudo reboot
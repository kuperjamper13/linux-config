#!/bin/bash

# ==============================================================================
#  AESTHETIC CONFIGURATION (CYBERPUNK TERMINAL THEME)
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

# Text Icons (Strictly ASCII)
ICON_OK="[${GREEN} OK ${NC}]"
ICON_ERR="[${RED}FAIL${NC}]"
ICON_ASK="[${MAGENTA} ?? ${NC}]"
ICON_INF="[${CYAN} :: ${NC}]"

# UI Helpers
function draw_line {
    echo -e "${DIM}────────────────────────────────────────────────────────────${NC}"
}

function show_header {
    clear
    echo -e "${MAGENTA}"
    echo " ▄▄▄        ██▀███    ▄████▄    ██░ ██ "
    echo "▒████▄     ▓██ ▒ ██▒▒██▀ ▀█   ▓██░ ██▒"
    echo "▒██  ▀█▄   ▓██ ░▄█ ▒▒▓█    ▄  ▒██▀▀██░"
    echo "░██▄▄▄▄██  ▒██▀▀█▄   ▒▓▓▄ ▄██ ░▓█ ░██ "
    echo " ▓█    ▓██▒░██▓ ▒██▒▒ ▓███▀ ░░▓█▒░██▓"
    echo " ▒▒    ▓▒█░░ ▒▓ ░▒▓░░ ░▒ ▒  ░ ▒ ░░▒░▒"
    echo "  ▒    ▒▒ ░  ░▒ ░ ▒░  ░  ▒     ▒ ░▒░ ░"
    echo "  ░    ▒     ░░   ░ ░          ░  ░░ ░"
    echo "       ░  ░   ░      ░ ░       ░  ░  ░"
    echo -e "${NC}"
    echo -e "${CYAN}   // AUTOMATED INSTALLATION SYSTEM v3.1 //${NC}"
    draw_line
}

function step_title {
    echo -e "\n${CYAN}┌──[ STEP $1/6 ] :: $2${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────${NC}"
}

show_header

# ==============================================================================
# 1. HOSTNAME
# ==============================================================================
step_title "1" "SYSTEM IDENTITY"
echo -e "${WHITE}Name your machine on the network.${NC}"
echo -e "${DIM}Examples: arch-station, reactor-core, ghost-shell${NC}\n"

read -p "$(echo -e "${ICON_ASK} Enter Hostname [default: arch-linux]: ${NC}")" MY_HOSTNAME
[[ -z "$MY_HOSTNAME" ]] && MY_HOSTNAME="arch-linux"
echo -e "${ICON_OK} Hostname set to: ${BOLD}$MY_HOSTNAME${NC}"

# ==============================================================================
# 2. KEYBOARD
# ==============================================================================
step_title "2" "INPUT CONFIGURATION"
echo -e "${WHITE}Select your physical keyboard layout:${NC}"

PS3=$(echo -e "\n${ICON_ASK} Select Number: ${NC}")
options=("US (ANSI)" "ES (ISO Spanish)" "LATAM" "UK" "DE" "FR" "PT" "IT" "RU" "JP" "Manual Input")

select opt in "${options[@]}"; do
    case $REPLY in
        1) KEYMAP="us"; break ;;
        2) KEYMAP="es"; break ;;
        3) KEYMAP="la-latin1"; break ;;
        4) KEYMAP="uk"; break ;;
        5) KEYMAP="de-latin1"; break ;;
        6) KEYMAP="fr"; break ;;
        7) KEYMAP="pt-latin1"; break ;;
        8) KEYMAP="it"; break ;;
        9) KEYMAP="ru"; break ;;
        10) KEYMAP="jp106"; break ;;
        11) read -p "Enter code: " KEYMAP; break ;;
        *) echo -e "${ICON_ERR} Invalid option.";;
    esac
done
echo -e "${ICON_OK} Keymap set to: ${BOLD}$KEYMAP${NC}"

# ==============================================================================
# 3. LOCALE
# ==============================================================================
step_title "3" "SYSTEM LANGUAGE"
echo -e "${WHITE}Select system display language:${NC}"
echo -e "${DIM}(English is recommended for development)${NC}"

PS3=$(echo -e "\n${ICON_ASK} Select Number: ${NC}")
locales=("English (US)" "Spanish (Spain)" "Spanish (Mexico)" "French" "German" "Portuguese" "Italian" "Russian" "Japanese" "Chinese" "Manual Input")

select opt in "${locales[@]}"; do
    case $REPLY in
        1) LOCALE="en_US.UTF-8"; break ;;
        2) LOCALE="es_ES.UTF-8"; break ;;
        3) LOCALE="es_MX.UTF-8"; break ;;
        4) LOCALE="fr_FR.UTF-8"; break ;;
        5) LOCALE="de_DE.UTF-8"; break ;;
        6) LOCALE="pt_BR.UTF-8"; break ;;
        7) LOCALE="it_IT.UTF-8"; break ;;
        8) LOCALE="ru_RU.UTF-8"; break ;;
        9) LOCALE="ja_JP.UTF-8"; break ;;
        10) LOCALE="zh_CN.UTF-8"; break ;;
        11) read -p "Enter code (e.g. en_GB.UTF-8): " LOCALE; break ;;
        *) echo -e "${ICON_ERR} Invalid option.";;
    esac
done
echo -e "${ICON_OK} Locale set to: ${BOLD}$LOCALE${NC}"

# ==============================================================================
# 4. TIMEZONE (NESTED MENU)
# ==============================================================================
step_title "4" "TIMEZONE SELECTOR"
echo -e "${WHITE}Follow the menus to locate your city.${NC}"

# 1. REGION SELECTION
echo -e "\n${CYAN}:: Select Continent / Region ::${NC}"
PS3=$(echo -e "\n${ICON_ASK} Region Number: ${NC}")

# Get list of top-level regions (filtering out noise like right, posix, etc)
regions=$(find /usr/share/zoneinfo -maxdepth 1 -type d | cut -d/ -f5 | grep -vE "posix|right|Etc|SystemV|iso3166|Arctic|Antarctica")

select region in $regions; do
    if [[ -n "$region" ]]; then
        SELECTED_REGION=$region
        break
    else
        echo -e "${ICON_ERR} Invalid selection."
    fi
done

# 2. CITY SELECTION
echo -e "\n${CYAN}:: Select City in $SELECTED_REGION ::${NC}"
PS3=$(echo -e "\n${ICON_ASK} City Number (Press Enter to see more): ${NC}")

# List cities in that region
cities=$(ls /usr/share/zoneinfo/$SELECTED_REGION)

select city in $cities; do
    if [[ -n "$city" ]]; then
        TIMEZONE="$SELECTED_REGION/$city"
        break
    else
        echo -e "${ICON_ERR} Invalid selection."
    fi
done

echo -e "${ICON_OK} Timezone set to: ${BOLD}$TIMEZONE${NC}"

# ==============================================================================
# 5. NETWORK
# ==============================================================================
step_title "5" "CONNECTIVITY CHECK"

if ping -c 1 google.com &> /dev/null; then
    echo -e "${ICON_OK} ${GREEN}System is Online.${NC}"
else
    echo -e "${ICON_ERR} ${YELLOW}Offline.${NC} Initializing WiFi Wizard..."
    
    WIFI_INTERFACE=$(ip link | awk -F: '$0 !~ "lo|vir|eth" {print $2;getline}' | head -n 1 | tr -d ' ')
    
    echo -e "${ICON_INF} Scanning on ${BOLD}$WIFI_INTERFACE${NC}..."
    iwctl station $WIFI_INTERFACE scan
    iwctl station $WIFI_INTERFACE get-networks
    
    echo ""
    read -p "$(echo -e "${ICON_ASK} WiFi Name (SSID): ${NC}")" WIFI_SSID
    read -s -p "$(echo -e "${ICON_ASK} WiFi Password: ${NC}")" WIFI_PASS
    echo ""
    
    echo -e "${ICON_INF} Connecting..."
    iwctl --passphrase "$WIFI_PASS" station $WIFI_INTERFACE connect "$WIFI_SSID"
    sleep 5
    
    if ping -c 1 google.com &> /dev/null; then
        echo -e "${ICON_OK} ${GREEN}Connected Successfully.${NC}"
    else
        echo -e "${ICON_ERR} ${RED}Connection Failed.${NC}"
        echo "Check password or try manual connection."
        read -p "Press Enter to continue anyway..."
    fi
fi

# ==============================================================================
# 6. PARTITIONING
# ==============================================================================
show_header
step_title "6" "INSTALLATION TARGET"
echo -e "${WHITE}Choose your deployment strategy:${NC}\n"

echo -e "${BOLD}[1] MANUAL MODE${NC} (Dual Boot / Real Hardware)"
echo -e "    ${DIM}Safe. You select existing partitions (Root & EFI).${NC}"
echo ""
echo -e "${BOLD}[2] AUTO MODE${NC} (Virtual Machine / Clean Wipe)"
echo -e "    ${DIM}Automatic. Wipes entire disk. Creates partitions.${NC}"
echo -e "    ${RED}WARNING: DATA DESTRUCTION.${NC}"
echo ""

read -p "$(echo -e "${ICON_ASK} Select Mode [1 or 2]: ${NC}")" PART_MODE

if [ "$PART_MODE" == "2" ]; then
    # --- AUTO MODE ---
    echo -e "\n${CYAN}:: Available Disks ::${NC}"
    lsblk -d -o NAME,SIZE,MODEL
    echo ""
    read -p "$(echo -e "${ICON_ERR} Enter disk to WIPE (e.g. /dev/vda): ${NC}")" TARGET_DISK
    
    echo -e "\n${RED}========================================${NC}"
    echo -e "${RED}   DANGER: WIPING $TARGET_DISK          ${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    read -p "$(echo -e "${ICON_ASK} Type 'DESTROY' to confirm: ${NC}")" CONFIRM
    if [ "$CONFIRM" != "DESTROY" ]; then echo "Aborted."; exit 1; fi

    echo -e "${ICON_INF} Partitioning Drive..."
    sgdisk -Z $TARGET_DISK &>/dev/null
    sgdisk -n 1:0:+512M -t 1:ef00 $TARGET_DISK &>/dev/null
    sgdisk -n 2:0:0 -t 2:8304 $TARGET_DISK &>/dev/null
    partprobe $TARGET_DISK
    sleep 2

    if [[ "$TARGET_DISK" == *"nvme"* ]]; then
        EFI_PART="${TARGET_DISK}p1"; ROOT_PART="${TARGET_DISK}p2"
    else
        EFI_PART="${TARGET_DISK}1"; ROOT_PART="${TARGET_DISK}2"
    fi

else
    # --- MANUAL MODE ---
    echo -e "\n${CYAN}:: Partition Map ::${NC}"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT
    echo ""
    read -p "$(echo -e "${ICON_ASK} TARGET Partition (50GB+): ${NC}")" ROOT_PART
    read -p "$(echo -e "${ICON_ASK} EFI Partition (~500MB):   ${NC}")" EFI_PART
    
    echo -e "\n${CYAN}:: Summary ::${NC}"
    echo -e "Format: ${RED}$ROOT_PART${NC} (EXT4)"
    echo -e "Keep:   ${GREEN}$EFI_PART${NC} (EFI)"
    read -p "$(echo -e "${ICON_ASK} Type 'yes' to proceed: ${NC}")" CONFIRM
    if [ "$CONFIRM" != "yes" ]; then echo "Aborted."; exit 1; fi
fi

# ==============================================================================
# INSTALLATION PROCESS
# ==============================================================================
show_header
echo -e "${CYAN}:: SYSTEM INSTALLATION IN PROGRESS... ::${NC}"

# --- OPTIMIZATION START ---
echo -e "${ICON_INF} Configuring Parallel Downloads..."
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

echo -e "${ICON_INF} Selecting Stable Mirrors..."
echo -e "${DIM}(Filtering for HTTPS only to prevent download errors)${NC}"
pacman -Sy --noconfirm reflector &>/dev/null
# FIX: Protocol set to HTTPS only (prevents rsync errors), Age set to 24h (prevents dead mirrors)
reflector --protocol https --age 24 --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
# --- OPTIMIZATION END ---

# Format
echo -e "${ICON_INF} Formatting Root..."
mkfs.ext4 -F $ROOT_PART &>/dev/null
if [ "$PART_MODE" == "2" ]; then
    echo -e "${ICON_INF} Formatting EFI..."
    mkfs.vfat -F32 $EFI_PART &>/dev/null
fi

# Mount
echo -e "${ICON_INF} Mounting..."
mount $ROOT_PART /mnt
mkdir -p /mnt/boot
mount $EFI_PART /mnt/boot

# CPU Detection
echo -e "${ICON_INF} Detecting CPU Vendor..."
if grep -q "AuthenticAMD" /proc/cpuinfo; then
    MICROCODE="amd-ucode"
    echo -e "${ICON_OK} AMD CPU detected. Queuing ${BOLD}amd-ucode${NC}."
else
    MICROCODE="intel-ucode"
    echo -e "${ICON_OK} Intel CPU detected. Queuing ${BOLD}intel-ucode${NC}."
fi

# Install
echo -e "${ICON_INF} Downloading Packages..."
# Included: base system, zen kernel (speed), firmware, microcode, network, 
# mesa (graphics backend), pipewire (modern audio), power-profiles (battery)
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware base-devel clang git networkmanager nano \
    $MICROCODE mesa pipewire pipewire-alsa pipewire-pulse wireplumber power-profiles-daemon &>/dev/null

echo -e "${ICON_INF} Generating Filesystem Table..."
genfstab -U /mnt >> /mnt/etc/fstab

# ==============================================================================
# CONFIGURATION
# ==============================================================================
echo -e "\n${CYAN}:: USER ACCOUNTS ::${NC}"
read -p "$(echo -e "${ICON_ASK} New Username: ${NC}")" MY_USER
read -s -p "$(echo -e "${ICON_ASK} New Password: ${NC}")" MY_PASS
echo ""

export TIMEZONE LOCALE KEYMAP MY_HOSTNAME MY_USER MY_PASS

echo -e "${ICON_INF} Configuring System Internals..."
arch-chroot /mnt /bin/bash <<EOF
# 1. Time & Locales
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo "$LOCALE UTF-8" > /etc/locale.gen
locale-gen > /dev/null
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$MY_HOSTNAME" > /etc/hostname

# 2. Users & Passwords
echo "root:$MY_PASS" | chpasswd
useradd -m -G wheel,storage,power -s /bin/bash $MY_USER
echo "$MY_USER:$MY_PASS" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# 3. Bootloader
pacman -S --noconfirm grub efibootmgr os-prober > /dev/null
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch > /dev/null
grub-mkconfig -o /boot/grub/grub.cfg > /dev/null

# 4. Services
systemctl enable NetworkManager
systemctl enable power-profiles-daemon

# 5. Swap File (4GB - Prevents crashes)
echo "Creating Swapfile..."
dd if=/dev/zero of=/swapfile bs=1G count=4 status=none
chmod 600 /swapfile
mkswap /swapfile > /dev/null
swapon /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

# 6. Quality of Life
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
echo "set tabsize 4" > /home/$MY_USER/.nanorc
echo "set tabstospaces" >> /home/$MY_USER/.nanorc
chown $MY_USER:$MY_USER /home/$MY_USER/.nanorc
EOF

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}   INSTALLATION COMPLETE!               ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "1. Reboot."
echo -e "2. Log in as ${BOLD}$MY_USER${NC}."
echo -e "3. Install Hyprland & Rice."

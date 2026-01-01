#!/bin/bash

# ==============================================================================
#  ARCH CONFIGURATION AND INSTALLATION SCRIPT by kuperjamper13
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
ICON_WARN="[${YELLOW}WARN${NC}]"

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
    echo -e "${CYAN}   // AUTOMATED INSTALLATION SYSTEM v4.0 (UNIVERSAL) //${NC}"
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

    # Loop until connected
    while true; do
        echo -e "${CYAN}:: Enter WiFi Credentials ::${NC}"
        read -p "$(echo -e "${ICON_ASK} WiFi Name (SSID): ${NC}")" WIFI_SSID
        read -s -p "$(echo -e "${ICON_ASK} WiFi Password: ${NC}")" WIFI_PASS
        echo ""
        
        echo -e "${ICON_INF} Attempting connection to ${BOLD}$WIFI_SSID${NC}..."
        iwctl --passphrase "$WIFI_PASS" station $WIFI_INTERFACE connect "$WIFI_SSID"
        
        # Wait a bit longer for DHCP negotiation
        echo -e "${ICON_INF} Verifying connection (Waiting 8s)..."
        sleep 8
        
        if ping -c 1 google.com &> /dev/null; then
            echo -e "${ICON_OK} ${GREEN}Connected Successfully.${NC}"
            break
        else
            echo -e "${ICON_ERR} ${RED}Connection Failed or Wrong Password.${NC}"
            echo -e "${DIM}Please try again...${NC}\n"
        fi
    done
fi

# ==============================================================================
# 6. UNIVERSAL PARTITIONING (THE ADVISOR)
# ==============================================================================
show_header
step_title "6" "DISK STRATEGY"

# 1. DISK SELECTION
echo -e "${CYAN}:: Detected Storage Devices ::${NC}"
lsblk -d -n -o NAME,SIZE,MODEL,TYPE | grep 'disk' | awk '{print " /dev/" $1 " (" $2 ") - " $3}'
echo ""
read -p "$(echo -e "${ICON_ASK} Enter Target Drive (e.g. nvme0n1): ${NC}")" DISK_NAME
TARGET_DISK="/dev/$DISK_NAME"

# 2. SYSTEM ADVISOR
echo -e "\n${CYAN}:: System Advisor ::${NC}"
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$(($TOTAL_RAM_KB / 1024 / 1024))

echo -e " [RAM]  Detected ${BOLD}${TOTAL_RAM_GB}GB${NC} RAM."
if [ $TOTAL_RAM_GB -ge 8 ]; then
    echo -e "        ${GREEN}Recommendation:${NC} Use a SWAPFILE (Managed automatically)."
else
    echo -e "        ${YELLOW}Recommendation:${NC} RAM is low. We will create a large Swapfile."
fi

echo -e " [DISK] Selected ${BOLD}$TARGET_DISK${NC}."
echo -e "        ${GREEN}Recommendation:${NC} Create ${BOLD}ONE${NC} partition for Arch (Min 25GB)."
echo -e "        If dual-booting, leave Windows/Fedora partitions alone."

# 3. VISUAL EDITOR
echo -e "\n${CYAN}:: Launching Partition Editor ::${NC}"
echo -e "${DIM}1. Select 'Free Space' -> 'New'."
echo -e "2. Select Type 'Linux filesystem'."
echo -e "3. Select 'Write' -> type 'yes'."
echo -e "4. Select 'Quit'.${NC}"
read -p "Press Enter to open cfdisk..."
cfdisk $TARGET_DISK
partprobe $TARGET_DISK
sleep 2

# 4. EFI SELECTION (SMART DETECT)
echo -e "\n${CYAN}:: Boot Partition (EFI) Selection ::${NC}"
# Try to find existing EFI (look for vfat or ESP labels)
AUTO_EFI=$(fdisk -l $TARGET_DISK | grep 'EFI System' | awk '{print $1}' | head -n 1)

if [[ -n "$AUTO_EFI" ]]; then
    echo -e "${ICON_OK} Detected existing EFI Partition: ${BOLD}$AUTO_EFI${NC}"
    read -p "$(echo -e "${ICON_ASK} Use this partition for Boot? (Safe for Windows) [Y/n]: ${NC}")" USE_AUTO
    if [[ "$USE_AUTO" =~ ^[Nn]$ ]]; then
        AUTO_EFI="" # User rejected auto, force manual select
    else
        EFI_PART=$AUTO_EFI
        FORMAT_EFI="no" # PROTECT WINDOWS
    fi
fi

if [[ -z "$EFI_PART" ]]; then
    # Manual Select
    lsblk $TARGET_DISK -o NAME,SIZE,TYPE,FSTYPE,LABEL | grep 'part'
    read -p "$(echo -e "${ICON_ASK} Enter EFI Partition (e.g. ${DISK_NAME}p1): ${NC}")" EFI_PART
    EFI_PART="/dev/$EFI_PART"
    FORMAT_EFI="yes" # Assume new if manually picked and not auto-detected
fi

# 5. ROOT SELECTION
echo -e "\n${CYAN}:: Root Partition (System) Selection ::${NC}"
lsblk $TARGET_DISK -o NAME,SIZE,TYPE,FSTYPE,LABEL | grep 'part' | grep -v "$(basename $EFI_PART)"
read -p "$(echo -e "${ICON_ASK} Enter Root Partition (e.g. ${DISK_NAME}p3): ${NC}")" ROOT_PART
ROOT_PART="/dev/$ROOT_PART"

# 6. HOME SELECTION (OPTIONAL)
echo -e "\n${CYAN}:: Home Partition (Optional) ::${NC}"
read -p "$(echo -e "${ICON_ASK} Do you have a separate Home partition? [y/N]: ${NC}")" HAS_HOME
if [[ "$HAS_HOME" =~ ^[Yy]$ ]]; then
    read -p "$(echo -e "${ICON_ASK} Enter Home Partition: ${NC}")" HOME_PART
    HOME_PART="/dev/$HOME_PART"
fi

# 7. CONFIRMATION
echo -e "\n${RED}========================================${NC}"
echo -e "${RED}   FINAL CONFIRMATION                   ${NC}"
echo -e "${RED}========================================${NC}"
echo -e "Disk: ${BOLD}$TARGET_DISK${NC}"
echo -e "EFI:  ${GREEN}$EFI_PART${NC} (Format: $FORMAT_EFI)"
echo -e "Root: ${RED}$ROOT_PART${NC} (Format: YES - WIPES DATA)"
if [[ -n "$HOME_PART" ]]; then
    echo -e "Home: ${BLUE}$HOME_PART${NC} (Format: NO - KEEPS DATA)"
fi
echo ""
read -p "$(echo -e "${ICON_ASK} Type 'yes' to Install: ${NC}")" CONFIRM
if [ "$CONFIRM" != "yes" ]; then echo "Aborted."; exit 1; fi

# ==============================================================================
# INSTALLATION PROCESS
# ==============================================================================
show_header
echo -e "${CYAN}:: SYSTEM INSTALLATION IN PROGRESS... ::${NC}"

# --- OPTIMIZATION START ---
echo -e "${ICON_INF} Configuring Parallel Downloads..."
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
# --- OPTIMIZATION END ---

# Format Root
echo -e "${ICON_INF} Formatting Root ($ROOT_PART)..."
mkfs.ext4 -F $ROOT_PART &>/dev/null

# Format EFI (Only if new)
if [ "$FORMAT_EFI" == "yes" ]; then
    echo -e "${ICON_INF} Formatting EFI ($EFI_PART)..."
    mkfs.vfat -F32 $EFI_PART &>/dev/null
else
    echo -e "${ICON_INF} Skipping EFI Format (Preserving existing bootloader)..."
fi

# Mount
echo -e "${ICON_INF} Mounting System..."
mount $ROOT_PART /mnt
mkdir -p /mnt/boot
mount $EFI_PART /mnt/boot

# Mount Home (If selected)
if [[ -n "$HOME_PART" ]]; then
    echo -e "${ICON_INF} Mounting Home..."
    mkdir -p /mnt/home
    mount $HOME_PART /mnt/home
fi

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

# --- PASSWORD LOOP START ---
while true; do
    echo -e "${CYAN}:: Set Password for $MY_USER ::${NC}"
    read -s -p "$(echo -e "${ICON_ASK} Enter Password: ${NC}")" PASS1
    echo
    read -s -p "$(echo -e "${ICON_ASK} Confirm Password: ${NC}")" PASS2
    echo ""
    
    if [ "$PASS1" == "$PASS2" ] && [ ! -z "$PASS1" ]; then
        MY_PASS="$PASS1"
        echo -e "${ICON_OK} Password matched."
        break
    else
        echo -e "${ICON_ERR} Passwords do not match or are empty. Try again."
    fi
done
# --- PASSWORD LOOP END ---

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

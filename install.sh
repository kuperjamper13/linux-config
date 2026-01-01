#!/bin/bash

# ==============================================================================
#  UI INITIALIZATION & THEME
# ==============================================================================
# Reset
NC='\033[0m'

# Professional Palette
BOLD='\033[1m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
WHITE='\033[1;37m'
DIM='\033[2m'

# Standard Icons
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
    echo -e "${CYAN}   // ARCH LINUX INSTALLER v4.1 (STABLE) //${NC}"
    draw_line
}

function step_title {
    echo -e "\n${CYAN}┌──[ STEP $1/6 ] :: $2${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────${NC}"
}

show_header

# ==============================================================================
# 1. HOSTNAME CONFIGURATION
# ==============================================================================
step_title "1" "SYSTEM IDENTITY"
echo -e "${WHITE}Configure the network hostname for this machine.${NC}"

read -p "$(echo -e "${ICON_ASK} Enter Hostname [default: arch-linux]: ${NC}")" MY_HOSTNAME
[[ -z "$MY_HOSTNAME" ]] && MY_HOSTNAME="arch-linux"
echo -e "${ICON_OK} Hostname set to: ${BOLD}$MY_HOSTNAME${NC}"

# ==============================================================================
# 2. KEYBOARD LAYOUT
# ==============================================================================
step_title "2" "INPUT CONFIGURATION"
echo -e "${WHITE}Select physical keyboard layout:${NC}"

PS3=$(echo -e "\n${ICON_ASK} Select Option: ${NC}")
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
# 3. LOCALE CONFIGURATION
# ==============================================================================
step_title "3" "REGION & LANGUAGE"
echo -e "${WHITE}Select system display language:${NC}"

PS3=$(echo -e "\n${ICON_ASK} Select Option: ${NC}")
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
# 4. TIMEZONE SELECTION
# ==============================================================================
step_title "4" "TIMEZONE"
echo -e "${WHITE}Locate your city.${NC}"

# 1. REGION
echo -e "\n${CYAN}:: Select Continent / Region ::${NC}"
PS3=$(echo -e "\n${ICON_ASK} Select Region: ${NC}")
regions=$(find /usr/share/zoneinfo -maxdepth 1 -type d | cut -d/ -f5 | grep -vE "posix|right|Etc|SystemV|iso3166|Arctic|Antarctica")

select region in $regions; do
    if [[ -n "$region" ]]; then
        SELECTED_REGION=$region
        break
    else
        echo -e "${ICON_ERR} Invalid selection."
    fi
done

# 2. CITY
echo -e "\n${CYAN}:: Select City in $SELECTED_REGION ::${NC}"
PS3=$(echo -e "\n${ICON_ASK} Select City (Enter for more): ${NC}")
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
# 5. NETWORK SETUP
# ==============================================================================
step_title "5" "NETWORK CONNECTIVITY"

if ping -c 1 google.com &> /dev/null; then
    echo -e "${ICON_OK} ${GREEN}System is Online.${NC}"
else
    echo -e "${ICON_ERR} ${YELLOW}Offline.${NC} Initializing Network Manager..."
    
    WIFI_INTERFACE=$(ip link | awk -F: '$0 !~ "lo|vir|eth" {print $2;getline}' | head -n 1 | tr -d ' ')
    
    echo -e "${ICON_INF} Interface: ${BOLD}$WIFI_INTERFACE${NC}"
    iwctl station $WIFI_INTERFACE scan
    iwctl station $WIFI_INTERFACE get-networks
    echo ""

    while true; do
        echo -e "${CYAN}:: WiFi Credentials ::${NC}"
        read -p "$(echo -e "${ICON_ASK} SSID: ${NC}")" WIFI_SSID
        read -s -p "$(echo -e "${ICON_ASK} Password: ${NC}")" WIFI_PASS
        echo ""
        
        echo -e "${ICON_INF} Connecting to ${BOLD}$WIFI_SSID${NC}..."
        iwctl --passphrase "$WIFI_PASS" station $WIFI_INTERFACE connect "$WIFI_SSID"
        
        echo -e "${ICON_INF} Verifying (8s)..."
        sleep 8
        
        if ping -c 1 google.com &> /dev/null; then
            echo -e "${ICON_OK} ${GREEN}Connected.${NC}"
            break
        else
            echo -e "${ICON_ERR} ${RED}Connection Failed.${NC}"
            echo -e "${DIM}Retry credentials...${NC}\n"
        fi
    done
fi

# ==============================================================================
# 6. DISK CONFIGURATION (UNIVERSAL)
# ==============================================================================
show_header
step_title "6" "DISK PARTITIONING"

# 1. DISK SELECTION & SANITIZATION
echo -e "${CYAN}:: Available Storage ::${NC}"
lsblk -d -n -o NAME,SIZE,MODEL,TYPE | grep 'disk' | awk '{print " /dev/" $1 " (" $2 ") - " $3}'
echo ""

# FIX: Input Sanitization Loop
while true; do
    read -p "$(echo -e "${ICON_ASK} Enter Target Drive (e.g. nvme0n1 or /dev/vda): ${NC}")" DISK_INPUT
    
    # Strip '/dev/' if the user typed it, then add it back cleanly
    CLEAN_NAME=${DISK_INPUT#/dev/}
    TARGET_DISK="/dev/$CLEAN_NAME"

    if lsblk -d "$TARGET_DISK" &>/dev/null; then
        echo -e "${ICON_OK} Target selected: ${BOLD}$TARGET_DISK${NC}"
        break
    else
        echo -e "${ICON_ERR} Device $TARGET_DISK not found. Try again."
    fi
done

# 2. HARDWARE ANALYSIS
echo -e "\n${CYAN}:: System Analysis ::${NC}"
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$(($TOTAL_RAM_KB / 1024 / 1024))

echo -e " [RAM]  Detected ${BOLD}${TOTAL_RAM_GB}GB${NC}."
if [ $TOTAL_RAM_GB -ge 8 ]; then
    echo -e "        ${GREEN}Advice:${NC} Swap partition not required. Will use Swapfile."
else
    echo -e "        ${YELLOW}Advice:${NC} Low RAM. Will create optimized Swapfile."
fi

echo -e " [DISK] Target ${BOLD}$TARGET_DISK${NC}."
echo -e "        ${GREEN}Advice:${NC} Create 1 partition for Arch (Min 25GB)."
echo -e "        Leave existing Windows/Data partitions untouched."

# 3. PARTITION MANAGER
echo -e "\n${CYAN}:: Partition Manager (cfdisk) ::${NC}"
echo -e "${DIM}Instructions:"
echo -e "1. Highlight 'Free Space' > Select [ New ]."
echo -e "2. Select [ Type ] > 'Linux filesystem'."
echo -e "3. Select [ Write ] > Type 'yes'."
echo -e "4. Select [ Quit ].${NC}"
read -p "Press Enter to launch..."
cfdisk $TARGET_DISK
partprobe $TARGET_DISK
sleep 2

# 4. BOOT PARTITION (EFI)
echo -e "\n${CYAN}:: Boot Configuration (EFI) ::${NC}"
# Smart Detect
AUTO_EFI=$(fdisk -l $TARGET_DISK | grep 'EFI System' | awk '{print $1}' | head -n 1)

if [[ -n "$AUTO_EFI" ]]; then
    echo -e "${ICON_OK} Detected Windows Boot Manager: ${BOLD}$AUTO_EFI${NC}"
    read -p "$(echo -e "${ICON_ASK} Use this for Boot? (Safe/Dual-Boot) [Y/n]: ${NC}")" USE_AUTO
    if [[ "$USE_AUTO" =~ ^[Nn]$ ]]; then
        AUTO_EFI="" 
    else
        EFI_PART=$AUTO_EFI
        FORMAT_EFI="no" # PROTECT WINDOWS
    fi
fi

if [[ -z "$EFI_PART" ]]; then
    # Manual Select
    lsblk $TARGET_DISK -o NAME,SIZE,TYPE,FSTYPE,LABEL | grep 'part'
    read -p "$(echo -e "${ICON_ASK} Select EFI Partition (e.g. ${CLEAN_NAME}p1): ${NC}")" EFI_INPUT
    # Sanitize input again just in case
    EFI_CLEAN=${EFI_INPUT#/dev/}
    EFI_PART="/dev/$EFI_CLEAN"
    FORMAT_EFI="yes" 
fi

# 5. ROOT PARTITION
echo -e "\n${CYAN}:: Root Partition (System) ::${NC}"
lsblk $TARGET_DISK -o NAME,SIZE,TYPE,FSTYPE,LABEL | grep 'part' | grep -v "$(basename $EFI_PART)"
read -p "$(echo -e "${ICON_ASK} Select Root Partition (e.g. ${CLEAN_NAME}p3): ${NC}")" ROOT_INPUT
ROOT_CLEAN=${ROOT_INPUT#/dev/}
ROOT_PART="/dev/$ROOT_CLEAN"

# 6. HOME PARTITION (OPTIONAL)
echo -e "\n${CYAN}:: Home Partition (Optional) ::${NC}"
read -p "$(echo -e "${ICON_ASK} Separate Home partition? [y/N]: ${NC}")" HAS_HOME
if [[ "$HAS_HOME" =~ ^[Yy]$ ]]; then
    read -p "$(echo -e "${ICON_ASK} Select Home Partition: ${NC}")" HOME_INPUT
    HOME_CLEAN=${HOME_INPUT#/dev/}
    HOME_PART="/dev/$HOME_CLEAN"
fi

# 7. CONFIRMATION
echo -e "\n${RED}========================================${NC}"
echo -e "${RED}   CONFIRM INSTALLATION TARGETS         ${NC}"
echo -e "${RED}========================================${NC}"
echo -e "Disk: ${BOLD}$TARGET_DISK${NC}"
echo -e "EFI:  ${GREEN}$EFI_PART${NC} (Format: $FORMAT_EFI)"
echo -e "Root: ${RED}$ROOT_PART${NC} (Format: YES - WIPE)"
if [[ -n "$HOME_PART" ]]; then
    echo -e "Home: ${BLUE}$HOME_PART${NC} (Format: NO - KEEP DATA)"
fi
echo ""
read -p "$(echo -e "${ICON_ASK} Type 'yes' to Install: ${NC}")" CONFIRM
if [ "$CONFIRM" != "yes" ]; then echo "Aborted."; exit 1; fi

# ==============================================================================
# INSTALLATION PROCESS
# ==============================================================================
show_header
echo -e "${CYAN}:: INSTALLING SYSTEM BASE ::${NC}"

# Optimization
echo -e "${ICON_INF} Enabling Parallel Downloads..."
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

# Formatting
echo -e "${ICON_INF} Formatting Root ($ROOT_PART)..."
mkfs.ext4 -F $ROOT_PART &>/dev/null

if [ "$FORMAT_EFI" == "yes" ]; then
    echo -e "${ICON_INF} Formatting EFI ($EFI_PART)..."
    mkfs.vfat -F32 $EFI_PART &>/dev/null
else
    echo -e "${ICON_INF} Preserving EFI Bootloader..."
fi

# Mounting
echo -e "${ICON_INF} Mounting..."
mount $ROOT_PART /mnt
mkdir -p /mnt/boot
mount $EFI_PART /mnt/boot

if [[ -n "$HOME_PART" ]]; then
    mkdir -p /mnt/home
    mount $HOME_PART /mnt/home
fi

# CPU Microcode
echo -e "${ICON_INF} Detecting CPU..."
if grep -q "AuthenticAMD" /proc/cpuinfo; then
    MICROCODE="amd-ucode"
else
    MICROCODE="intel-ucode"
fi

# Pacstrap
echo -e "${ICON_INF} Installing Packages..."
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware base-devel clang git networkmanager nano \
    $MICROCODE mesa pipewire pipewire-alsa pipewire-pulse wireplumber power-profiles-daemon &>/dev/null

echo -e "${ICON_INF} Generating Fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# ==============================================================================
# SYSTEM CONFIGURATION
# ==============================================================================
echo -e "\n${CYAN}:: USER CONFIGURATION ::${NC}"
read -p "$(echo -e "${ICON_ASK} Username: ${NC}")" MY_USER

while true; do
    echo -e "${CYAN}:: Password for $MY_USER ::${NC}"
    read -s -p "$(echo -e "${ICON_ASK} Password: ${NC}")" PASS1
    echo
    read -s -p "$(echo -e "${ICON_ASK} Confirm:  ${NC}")" PASS2
    echo ""
    
    if [ "$PASS1" == "$PASS2" ] && [ ! -z "$PASS1" ]; then
        MY_PASS="$PASS1"
        break
    else
        echo -e "${ICON_ERR} Mismatch. Try again."
    fi
done

export TIMEZONE LOCALE KEYMAP MY_HOSTNAME MY_USER MY_PASS

echo -e "${ICON_INF} Configuring System..."
arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo "$LOCALE UTF-8" > /etc/locale.gen
locale-gen > /dev/null
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$MY_HOSTNAME" > /etc/hostname

echo "root:$MY_PASS" | chpasswd
useradd -m -G wheel,storage,power -s /bin/bash $MY_USER
echo "$MY_USER:$MY_PASS" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

pacman -S --noconfirm grub efibootmgr os-prober > /dev/null
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch > /dev/null
grub-mkconfig -o /boot/grub/grub.cfg > /dev/null

systemctl enable NetworkManager
systemctl enable power-profiles-daemon

# Swapfile (4GB)
dd if=/dev/zero of=/swapfile bs=1G count=4 status=none
chmod 600 /swapfile
mkswap /swapfile > /dev/null
swapon /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

# Nano Config
echo "set tabsize 4" > /home/$MY_USER/.nanorc
echo "set tabstospaces" >> /home/$MY_USER/.nanorc
chown $MY_USER:$MY_USER /home/$MY_USER/.nanorc
EOF

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}   INSTALLATION COMPLETE                ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "1. Remove installation media."
echo -e "2. Type 'reboot'."

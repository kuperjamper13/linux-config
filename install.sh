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
    echo -e "${CYAN}   // ARCH LINUX INSTALLER v5.1 (LTS) //${NC}"
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
# 6. DISK CONFIGURATION (AUTOMATED)
# ==============================================================================
show_header
step_title "6" "DISK PARTITIONING"

# 1. DISK SELECTION
echo -e "${CYAN}:: Available Storage ::${NC}"
lsblk -d -n -o NAME,SIZE,MODEL,TYPE | grep 'disk' | awk '{print " /dev/" $1 " (" $2 ") - " $3}'
echo ""

while true; do
    read -p "$(echo -e "${ICON_ASK} Enter Target Drive (e.g. nvme0n1 or /dev/vda): ${NC}")" DISK_INPUT
    CLEAN_NAME=${DISK_INPUT#/dev/}
    TARGET_DISK="/dev/$CLEAN_NAME"

    if lsblk -d "$TARGET_DISK" &>/dev/null; then
        echo -e "${ICON_OK} Target selected: ${BOLD}$TARGET_DISK${NC}"
        break
    else
        echo -e "${ICON_ERR} Device $TARGET_DISK not found. Try again."
    fi
done

# 2. STRATEGY SELECTION
echo -e "\n${CYAN}:: Partitioning Strategy ::${NC}"
echo -e "${BOLD}[1] Use Free Space (Dual Boot / Safe)${NC}"
echo -e "    Autofills empty space. Preserves Windows/Data."
echo -e "${BOLD}[2] Erase Whole Disk (Clean Install)${NC}"
echo -e "    Deletes EVERYTHING. Creates new structure."
echo -e "${BOLD}[3] Manual Mode (Advanced)${NC}"
echo -e "    Open partition editor."

read -p "$(echo -e "\n${ICON_ASK} Select Option [1-3]: ${NC}")" STRATEGY

# 3. APPLY STRATEGY
if [ "$STRATEGY" == "2" ]; then
    # --- ERASE ALL ---
    echo -e "\n${RED}WARNING: ALL DATA ON $TARGET_DISK WILL BE DESTROYED.${NC}"
    read -p "$(echo -e "${ICON_ASK} Type 'DESTROY' to confirm: ${NC}")" CONFIRM
    if [ "$CONFIRM" != "DESTROY" ]; then echo "Aborted."; exit 1; fi
    
    echo -e "${ICON_INF} Wiping Disk..."
    sgdisk -Z $TARGET_DISK &>/dev/null
    
    echo -e "${ICON_INF} Creating Partitions..."
    sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System Partition" $TARGET_DISK &>/dev/null
    sgdisk -n 2:0:0     -t 2:8304 -c 2:"Arch Linux Root"      $TARGET_DISK &>/dev/null
    partprobe $TARGET_DISK
    sleep 2
    
    if [[ "$TARGET_DISK" == *"nvme"* ]]; then
        EFI_PART="${TARGET_DISK}p1"; ROOT_PART="${TARGET_DISK}p2"
    else
        EFI_PART="${TARGET_DISK}1"; ROOT_PART="${TARGET_DISK}2"
    fi
    FORMAT_EFI="yes"

elif [ "$STRATEGY" == "1" ]; then
    # --- USE FREE SPACE ---
    echo -e "${ICON_INF} Detecting Free Space..."
    sgdisk -n 0:0:0 -t 0:8304 -c 0:"Arch Linux Root" $TARGET_DISK
    partprobe $TARGET_DISK
    sync
    sleep 2
    
    # Auto-detect Root (Extract Path Column 1)
    ROOT_PART=$(lsblk -n -o PATH,PARTLABEL $TARGET_DISK | grep "Arch Linux Root" | tail -n1 | awk '{print $1}')
    
    if [[ -z "$ROOT_PART" ]]; then
        echo -e "${ICON_ERR} Could not auto-detect new partition. Manual entry required:"
        lsblk $TARGET_DISK -o NAME,SIZE,TYPE,LABEL
        read -p "Enter Partition Name (e.g. nvme0n1p3): " ROOT_INPUT
        ROOT_PART="/dev/${ROOT_INPUT#/dev/}"
    fi
    
    # Auto-Detect EFI
    AUTO_EFI=$(fdisk -l $TARGET_DISK | grep 'EFI System' | awk '{print $1}' | head -n 1)
    if [[ -n "$AUTO_EFI" ]]; then
        EFI_PART=$AUTO_EFI
        FORMAT_EFI="no"
        echo -e "${ICON_OK} Auto-selected EFI: ${BOLD}$EFI_PART${NC}"
    else
        echo -e "${ICON_ERR} No EFI partition found. System requires EFI to boot."
        exit 1
    fi

else
    # --- MANUAL MODE ---
    cfdisk $TARGET_DISK
    partprobe $TARGET_DISK
    sleep 2
    echo -e "\n${CYAN}:: Identify Partitions ::${NC}"
    lsblk $TARGET_DISK -o NAME,SIZE,TYPE,FSTYPE,LABEL
    
    read -p "$(echo -e "${ICON_ASK} Select EFI Partition: ${NC}")" EFI_INPUT
    EFI_PART="/dev/${EFI_INPUT#/dev/}"
    read -p "$(echo -e "${ICON_ASK} Format EFI? (yes/no): ${NC}")" FORMAT_EFI
    
    read -p "$(echo -e "${ICON_ASK} Select Root Partition: ${NC}")" ROOT_INPUT
    ROOT_PART="/dev/${ROOT_INPUT#/dev/}"
fi

# 4. FINAL VERIFICATION
if [ ! -b "$ROOT_PART" ] || [ ! -b "$EFI_PART" ]; then
    echo -e "\n${ICON_ERR} CRITICAL ERROR: Defined partition does not exist."
    echo -e "Root: $ROOT_PART"
    echo -e "EFI:  $EFI_PART"
    exit 1
fi

echo -e "\n${RED}========================================${NC}"
echo -e "${RED}   CONFIRM INSTALLATION TARGETS         ${NC}"
echo -e "${RED}========================================${NC}"
echo -e "Disk: ${BOLD}$TARGET_DISK${NC}"
echo -e "EFI:  ${GREEN}$EFI_PART${NC} (Format: $FORMAT_EFI)"
echo -e "Root: ${RED}$ROOT_PART${NC} (Format: YES - WIPE)"
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

# CPU Microcode
echo -e "${ICON_INF} Detecting CPU..."
if grep -q "AuthenticAMD" /proc/cpuinfo; then
    MICROCODE="amd-ucode"
else
    MICROCODE="intel-ucode"
fi

# Pacstrap
echo -e "${ICON_INF} Installing Packages..."
# Added 'ntfs-3g' (Windows access) and 'dosfstools' (EFI tools) and 'bluez'
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware base-devel clang git networkmanager nano \
    $MICROCODE mesa pipewire pipewire-alsa pipewire-pulse wireplumber power-profiles-daemon \
    bluez bluez-utils ntfs-3g dosfstools &>/dev/null

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

echo -e "${ICON_INF} Configuring System Internals..."
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
systemctl enable bluetooth
systemctl enable fstrim.timer

sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j\$(nproc)\"/" /etc/makepkg.conf

dd if=/dev/zero of=/swapfile bs=1G count=4 status=none
chmod 600 /swapfile
mkswap /swapfile > /dev/null
swapon /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

echo "set tabsize 4" > /home/$MY_USER/.nanorc
echo "set tabstospaces" >> /home/$MY_USER/.nanorc
chown $MY_USER:$MY_USER /home/$MY_USER/.nanorc
EOF

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}   INSTALLATION COMPLETE                ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "1. Remove installation media."
echo -e "2. Type 'reboot'."
echo -e "3. Login as ${BOLD}$MY_USER${NC}."

#!/bin/bash

# ==============================================================================
#  ARCH LINUX UNIVERSAL INSTALLER v1.2.0
#  Enterprise Grade | Dual-Boot Safe | Neon Aesthetic
# ==============================================================================

# --- [1] VISUAL LIBRARY -------------------------------------------------------
# Reset
NC='\033[0m'

# Flashy Neon Palette (Bright/Bold)
BOLD='\033[1m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
WHITE='\033[1;37m'
DIM='\033[2m'

# Status Indicators
ICON_OK="[${GREEN}  OK  ${NC}]"
ICON_ERR="[${RED} FAIL ${NC}]"
ICON_WRN="[${YELLOW} WARN ${NC}]"
ICON_ASK="[${MAGENTA}  ??  ${NC}]"
ICON_INF="[${CYAN} INFO ${NC}]"

# --- [2] UI UTILITIES ---------------------------------------------------------
function print_banner {
    echo -e "${MAGENTA}"
    echo " ▄▄▄       ██████╗  ▄▄▄▄█████╗ ██╗  ██╗"
    echo " ████╗     ██╔══██╗ ██╔▄▄▄▄▄═╝ ██║  ██║"
    echo " ██╔██╗    ██████╔╝ ██║        ███████║"
    echo " ██║╚██╗   ██╔══██╗ ██║        ██╔══██║"
    echo " ██║ ╚██╗  ██║  ██║ ████████╗  ██║  ██║"
    echo " ╚═╝  ╚═╝  ╚═╝  ╚═╝ ╚═══════╝  ╚═╝  ╚═╝"
    echo "  >> UNIVERSAL INSTALLER SYSTEM v1.2.0"
    echo -e "${NC}"
}

function start_step {
    # Clears screen and re-draws banner for a clean look per step
    clear
    print_banner
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD} STEP $1 :: $2 ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}\n"
}

function ask_input {
    # High visibility input prompt
    # Usage: ask_input "VARIABLE" "Prompt Text" "Default (optional)"
    local var_name=$1
    local prompt_text=$2
    local default_val=$3
    
    if [[ -n "$default_val" ]]; then
        echo -ne "${YELLOW}${BOLD} ➜ ${NC}${WHITE}$prompt_text${NC} [${DIM}$default_val${NC}]: "
    else
        echo -ne "${YELLOW}${BOLD} ➜ ${NC}${WHITE}$prompt_text${NC}: "
    fi
    read -r input_val
    
    if [[ -z "$input_val" && -n "$default_val" ]]; then
        eval $var_name="'$default_val'"
    else
        eval $var_name="'$input_val'"
    fi
}

# ==============================================================================
# SECTION 1: SYSTEM IDENTITY
# ==============================================================================
start_step "1" "SYSTEM IDENTITY CONFIGURATION"

# 1.1 Hostname
echo -e "${ICON_INF} Configure the network identity for this machine."
ask_input "MY_HOSTNAME" "Enter Hostname" "arch-linux"
echo -e "${ICON_OK} Hostname set to: ${BOLD}$MY_HOSTNAME${NC}"

# ==============================================================================
# SECTION 2: INPUT & REGION
# ==============================================================================
start_step "2" "REGIONAL SETTINGS"

# 2.1 Keyboard
echo -e "${ICON_INF} Select Physical Keyboard Layout"
PS3=$(echo -e "${YELLOW}${BOLD} ➜ ${NC}Select Option: ")
options=("us" "es" "la-latin1" "uk" "de-latin1" "fr" "pt-latin1" "it" "ru" "jp106")
select KEYMAP in "${options[@]}"; do
    [[ -n "$KEYMAP" ]] && break
    echo -e "${ICON_ERR} Invalid selection."
done

# 2.2 Locale
echo -e "\n${ICON_INF} Select System Display Language"
PS3=$(echo -e "${YELLOW}${BOLD} ➜ ${NC}Select Option: ")
locales=("en_US.UTF-8" "es_ES.UTF-8" "es_MX.UTF-8" "fr_FR.UTF-8" "de_DE.UTF-8" "pt_BR.UTF-8" "it_IT.UTF-8" "ru_RU.UTF-8" "ja_JP.UTF-8" "zh_CN.UTF-8")
select LOCALE in "${locales[@]}"; do
    [[ -n "$LOCALE" ]] && break
    echo -e "${ICON_ERR} Invalid selection."
done

# 2.3 Timezone (Nested)
echo -e "\n${ICON_INF} Select Timezone Region"
PS3=$(echo -e "${YELLOW}${BOLD} ➜ ${NC}Select Region: ")
regions=$(find /usr/share/zoneinfo -maxdepth 1 -type d | cut -d/ -f5 | grep -vE "posix|right|Etc|SystemV|iso3166|Arctic|Antarctica")
select REGION in $regions; do
    [[ -n "$REGION" ]] && break
    echo -e "${ICON_ERR} Invalid selection."
done

echo -e "\n${ICON_INF} Select City in $REGION"
PS3=$(echo -e "${YELLOW}${BOLD} ➜ ${NC}Select City (Press Enter for more): ")
cities=$(ls /usr/share/zoneinfo/$REGION)
select CITY in $cities; do
    [[ -n "$CITY" ]] && break
    echo -e "${ICON_ERR} Invalid selection."
done
TIMEZONE="$REGION/$CITY"
echo -e "${ICON_OK} Timezone set to: ${BOLD}$TIMEZONE${NC}"

# ==============================================================================
# SECTION 3: NETWORK CONNECTIVITY
# ==============================================================================
start_step "3" "NETWORK CONNECTIVITY CHECK"

if ping -c 1 google.com &> /dev/null; then
    echo -e "${ICON_OK} Internet Connection: ${GREEN}Active${NC}"
else
    echo -e "${ICON_ERR} Internet Connection: ${RED}Offline${NC}"
    echo -e "${DIM}Initializing Wireless Interface...${NC}"
    
    # Auto-detect wireless interface excluding loopback/virtual/ethernet
    WIFI_INTERFACE=$(ip link | awk -F: '$0 !~ "lo|vir|eth" {print $2;getline}' | head -n 1 | tr -d ' ')
    
    echo -e "${ICON_INF} Scanning on Interface: ${BOLD}$WIFI_INTERFACE${NC}"
    iwctl station $WIFI_INTERFACE scan
    
    echo -e "\n${CYAN}:: Available Networks ::${NC}"
    iwctl station $WIFI_INTERFACE get-networks
    echo ""

    # Persistent Connection Loop
    while true; do
        echo -e "${ICON_ASK} WiFi Authentication Required"
        ask_input "WIFI_SSID" "SSID Name"
        
        # Manual password read for masking
        echo -ne "${YELLOW}${BOLD} ➜ ${NC}${WHITE}Password${NC}: "
        read -s WIFI_PASS
        echo ""
        
        echo -e "${ICON_INF} Authenticating with ${BOLD}$WIFI_SSID${NC}..."
        iwctl --passphrase "$WIFI_PASS" station $WIFI_INTERFACE connect "$WIFI_SSID"
        
        echo -e "${ICON_INF} Verifying Handshake (8s timeout)..."
        sleep 8
        
        if ping -c 1 google.com &> /dev/null; then
            echo -e "${ICON_OK} ${GREEN}Connection Established Successfully.${NC}"
            # Sync clock now that we have internet
            timedatectl set-ntp true
            break
        else
            echo -e "${ICON_ERR} ${RED}Connection Failed.${NC} Check password or signal strength."
            echo -e "${DIM}Retrying authentication sequence...${NC}\n"
        fi
    done
fi

# ==============================================================================
# SECTION 4: STORAGE CONFIGURATION
# ==============================================================================
start_step "4" "STORAGE ARCHITECTURE"

# 4.1 Drive Selection
echo -e "${ICON_INF} Detected Storage Devices:"
lsblk -d -n -o NAME,SIZE,MODEL,TYPE | grep 'disk' | awk '{print "    • /dev/" $1 " [" $2 "] " $3}'
echo ""

while true; do
    ask_input "DRIVE_INPUT" "Enter Target Drive (e.g. nvme0n1)"
    
    # Sanitize input: Ensure /dev/ prefix exists but handle duplicates
    CLEAN_NAME=${DRIVE_INPUT#/dev/}
    TARGET_DISK="/dev/$CLEAN_NAME"
    
    if lsblk -d "$TARGET_DISK" &>/dev/null; then
        echo -e "${ICON_OK} Target Locked: ${BOLD}$TARGET_DISK${NC}"
        break
    else
        echo -e "${ICON_ERR} Device not found. Please verify the name."
    fi
done

# 4.2 System Advisor (Hardware Analysis)
echo -e "\n${ICON_INF} Running Hardware Analysis..."
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$(($TOTAL_RAM_KB / 1024 / 1024))

echo -e "   [RAM]  Detected ${BOLD}${TOTAL_RAM_GB}GB${NC} System Memory."
if [ $TOTAL_RAM_GB -ge 8 ]; then
    echo -e "          -> Strategy: Standard Swapfile (4GB) recommended."
else
    echo -e "          -> Strategy: ${YELLOW}Low Memory Detected.${NC} Swapfile is critical."
fi

# 4.3 Strategy Selection
echo -e "\n${ICON_INF} Select Partitioning Strategy"
echo -e " ${BOLD}[1] Use Free Space${NC}  :: (Dual-Boot Safe) Auto-fills empty space. Preserves Windows."
echo -e " ${BOLD}[2] Wipe Entire Disk${NC}:: (Clean Install)  Destroys ALL data. Creates fresh layout."
echo -e " ${BOLD}[3] Manual Mode${NC}     :: (Advanced User)  Launch visual partition editor."

echo ""
ask_input "STRATEGY" "Select Option [1-3]"

# 4.4 Execution Logic
case $STRATEGY in
    1)
        # --- USE FREE SPACE ---
        echo -e "${ICON_INF} Scanning for unallocated space..."
        # Create partition in largest free space block
        sgdisk -n 0:0:0 -t 0:8304 -c 0:"Arch Root" $TARGET_DISK
        partprobe $TARGET_DISK && sync && sleep 2
        
        # Identify the new partition by label (Auto-Detect)
        ROOT_PART=$(lsblk -n -o PATH,PARTLABEL $TARGET_DISK | grep "Arch Root" | tail -n1 | awk '{print $1}')
        
        # Fallback if auto-detect fails
        if [[ -z "$ROOT_PART" ]]; then
             echo -e "${ICON_WRN} Auto-detect failed. Please identify your new partition manually:"
             lsblk $TARGET_DISK -o NAME,SIZE,TYPE,LABEL
             ask_input "ROOT_INPUT" "Enter Root Partition Name (e.g. nvme0n1p3)"
             ROOT_PART="/dev/${ROOT_INPUT#/dev/}"
        fi
        
        # Find EFI (Dual Boot Logic)
        AUTO_EFI=$(fdisk -l $TARGET_DISK | grep 'EFI System' | awk '{print $1}' | head -n 1)
        if [[ -n "$AUTO_EFI" ]]; then
            EFI_PART=$AUTO_EFI
            FORMAT_EFI="no"
            echo -e "${ICON_OK} Detected existing Windows Boot Manager at ${BOLD}$EFI_PART${NC}"
        else
            echo -e "${ICON_ERR} No EFI Partition found. System requires EFI to boot."
            exit 1
        fi
        ;;
        
    2)
        # --- WIPE ALL ---
        echo -e "\n${RED}${BOLD}CRITICAL WARNING: THIS WILL DESTROY ALL DATA ON $TARGET_DISK${NC}"
        ask_input "CONFIRM" "Type 'DESTROY' to confirm"
        [[ "$CONFIRM" != "DESTROY" ]] && echo "Aborted." && exit 1
        
        echo -e "${ICON_INF} Initializing Disk Surface..."
        sgdisk -Z $TARGET_DISK &>/dev/null
        
        echo -e "${ICON_INF} Creating Partition Table..."
        sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System" $TARGET_DISK &>/dev/null
        sgdisk -n 2:0:0     -t 2:8304 -c 2:"Arch Root"  $TARGET_DISK &>/dev/null
        partprobe $TARGET_DISK && sync && sleep 2
        
        if [[ "$TARGET_DISK" == *"nvme"* ]]; then
            EFI_PART="${TARGET_DISK}p1"; ROOT_PART="${TARGET_DISK}p2"
        else
            EFI_PART="${TARGET_DISK}1"; ROOT_PART="${TARGET_DISK}2"
        fi
        FORMAT_EFI="yes"
        ;;
        
    3)
        # --- MANUAL ---
        echo -e "${ICON_INF} Launching cfdisk..."
        read -p "Press Enter to continue..."
        cfdisk $TARGET_DISK
        partprobe $TARGET_DISK && sync && sleep 2
        
        echo -e "\n${CYAN}:: Partition Map ::${NC}"
        lsblk $TARGET_DISK -o NAME,SIZE,TYPE,FSTYPE,LABEL
        
        ask_input "E_IN" "Select EFI Partition"
        EFI_PART="/dev/${E_IN#/dev/}"
        ask_input "FORMAT_EFI" "Format EFI? (yes/no)"
        
        ask_input "R_IN" "Select Root Partition"
        ROOT_PART="/dev/${R_IN#/dev/}"
        ;;
    *)
        echo "Invalid Option." && exit 1 ;;
esac

# 4.5 Safety Verification
if [ ! -b "$ROOT_PART" ] || [ ! -b "$EFI_PART" ]; then
    echo -e "${ICON_ERR} Partition topology check failed. Partitions do not exist."
    exit 1
fi

echo -e "\n${GREEN}=== CONFIGURATION SUMMARY ===${NC}"
echo -e " Target Disk : ${WHITE}$TARGET_DISK${NC}"
echo -e " EFI Boot    : ${WHITE}$EFI_PART${NC} (Format: $FORMAT_EFI)"
echo -e " System Root : ${WHITE}$ROOT_PART${NC} (Format: YES)"
echo -e "${GREEN}=============================${NC}"

ask_input "CONFIRM" "Type 'yes' to proceed with installation"
[[ "$CONFIRM" != "yes" ]] && exit 1

# ==============================================================================
# SECTION 5: INSTALLATION PROCESS
# ==============================================================================
start_step "5" "CORE INSTALLATION"

# 5.1 Optimization
echo -e "${ICON_INF} Optimizing Pacman (Enabling Parallel Downloads)..."
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

# 5.2 Formatting
echo -e "${ICON_INF} Formatting Filesystems..."
mkfs.ext4 -F $ROOT_PART &>/dev/null
if [[ "$FORMAT_EFI" == "yes" ]]; then
    echo -e "${ICON_INF} Formatting EFI Partition..."
    mkfs.vfat -F32 $EFI_PART &>/dev/null
else
    echo -e "${ICON_INF} Preserving existing EFI Data..."
fi

# 5.3 Mounting
echo -e "${ICON_INF} Mounting Partitions to /mnt..."
mount $ROOT_PART /mnt
mkdir -p /mnt/boot
mount $EFI_PART /mnt/boot

# 5.4 CPU Detection
echo -e "${ICON_INF} Detecting Processor Architecture..."
if grep -q "AuthenticAMD" /proc/cpuinfo; then
    UCODE="amd-ucode"
    echo -e "${ICON_OK} AMD CPU Detected."
else
    UCODE="intel-ucode"
    echo -e "${ICON_OK} Intel CPU Detected."
fi

# 5.5 Base Install
echo -e "${ICON_INF} Downloading and Installing Base System (This may take time)..."
# DRIVER EXPLANATION:
# - linux-zen: High performance kernel for gaming/desktop
# - mesa: OpenGL/Vulkan drivers for Intel/AMD/Nvidia
# - pipewire: Modern low-latency audio server
# - bluez: Bluetooth protocol stack
# - ntfs-3g: Read/Write support for Windows partitions
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware base-devel \
    $UCODE mesa pipewire pipewire-alsa pipewire-pulse wireplumber \
    networkmanager bluez bluez-utils power-profiles-daemon \
    git nano ntfs-3g dosfstools mtools &>/dev/null

echo -e "${ICON_OK} Core packages installed successfully."
echo -e "${ICON_INF} Generating Filesystem Table (fstab)..."
genfstab -U /mnt >> /mnt/etc/fstab

# ==============================================================================
# SECTION 6: SYSTEM CONFIGURATION (CHROOT)
# ==============================================================================
start_step "6" "USER & SYSTEM CONFIGURATION"

ask_input "MY_USER" "Enter Desired Username"
while true; do
    echo -ne "${YELLOW}${BOLD} ➜ ${NC}${WHITE}Password${NC}: "
    read -s P1; echo
    echo -ne "${YELLOW}${BOLD} ➜ ${NC}${WHITE}Confirm Password${NC}: "
    read -s P2; echo
    [[ "$P1" == "$P2" && -n "$P1" ]] && MY_PASS="$P1" && break
    echo -e "${ICON_ERR} Passwords do not match. Try again."
done

# Export variables for the Chroot environment
export TIMEZONE LOCALE KEYMAP MY_HOSTNAME MY_USER MY_PASS

echo -e "${ICON_INF} Configuring System Internals (Chroot)..."
arch-chroot /mnt /bin/bash <<EOF
# A. Time & Lang
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo "$LOCALE UTF-8" > /etc/locale.gen
locale-gen > /dev/null
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$MY_HOSTNAME" > /etc/hostname

# B. Users & Permissions
echo "root:$MY_PASS" | chpasswd
useradd -m -G wheel,storage,power,video -s /bin/bash $MY_USER
echo "$MY_USER:$MY_PASS" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# C. Bootloader (GRUB)
pacman -S --noconfirm grub efibootmgr os-prober > /dev/null
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch > /dev/null
grub-mkconfig -o /boot/grub/grub.cfg > /dev/null

# D. Services
systemctl enable NetworkManager
systemctl enable power-profiles-daemon
systemctl enable bluetooth
systemctl enable fstrim.timer

# E. Performance (Makeflags & Swap)
# Use all cores for compiling AUR packages
sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j\$(nproc)\"/" /etc/makepkg.conf

# Create 4GB Swapfile
dd if=/dev/zero of=/swapfile bs=1G count=4 status=none
chmod 600 /swapfile
mkswap /swapfile > /dev/null
swapon /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

# F. Editor Config (Nano)
echo "set tabsize 4" > /home/$MY_USER/.nanorc
echo "set tabstospaces" >> /home/$MY_USER/.nanorc
chown $MY_USER:$MY_USER /home/$MY_USER/.nanorc
EOF

# ==============================================================================
# FINALIZATION
# ==============================================================================
clear
print_banner
echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}   INSTALLATION SUCCESSFUL v1.2.0 ${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}"
echo -e ""
echo -e " 1. Remove installation media."
echo -e " 2. Type ${BOLD}reboot${NC} to start your new system."
echo -e " 3. Login as: ${BOLD}$MY_USER${NC}"
echo -e ""
echo -e "${DIM} Welcome to the Arch Linux family.${NC}"
echo -e ""

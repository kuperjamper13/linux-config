#!/bin/bash

# ==============================================================================
#  ARCH LINUX UNIVERSAL INSTALLER - ENTERPRISE EDITION v3.0.0
#  
#  DESCRIPTION: Installing arch made easy
#  AUTHOR:      kuperjamper13
#  LICENSE:     MIT
#  TARGET:      UEFI Systems (x86_64)
# ==============================================================================

# --- [0] GLOBAL CONFIGURATION -------------------------------------------------

# Error Handling: Exit on error, unset var, or pipe failure.
set -euo pipefail

# Configuration Constants
LOG_FILE="/var/log/arch-installer.log"
MOUNT_POINT="/mnt"
HOSTNAME_DEFAULT="arch-linux"

# Package Manifest - Separated for Maintainability
BASE_PACKAGES=(
    "base" "linux-zen" "linux-zen-headers" "linux-firmware" "base-devel"
    "mesa" "pipewire" "pipewire-alsa" "pipewire-pulse" "wireplumber"
    "networkmanager" "bluez" "bluez-utils" "power-profiles-daemon"
    "git" "nano" "ntfs-3g" "dosfstools" "mtools" "man-db"
)

# --- [1] VISUAL LIBRARY (STRICT PRESERVATION) ---------------------------------
# Adhering to requested aesthetic standards.

NC='\033[0m'
BOLD='\033[1m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
WHITE='\033[1;37m'
DIM='\033[2m'

ICON_OK="[${GREEN}  OK  ${NC}]"
ICON_ERR="[${RED} FAIL ${NC}]"
ICON_WRN="[${YELLOW} WARN ${NC}]"
ICON_ASK="[${MAGENTA}  ??  ${NC}]"
ICON_INF="[${CYAN} INFO ${NC}]"

# --- [2] UTILITY FUNCTIONS ----------------------------------------------------

# Logging Utility: Writes to log file and optionally to stdout if needed for debug.
log() {
    local msg="$1"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $msg" >> "$LOG_FILE"
}

# Cleanup Trap: Ensures terminal cursor is restored and logs exit.
cleanup() {
    local exit_code=$?
    tput cnorm 2>/dev/null || true
    if [ $exit_code -ne 0 ]; then
        echo -e "\n${ICON_ERR} Script aborted unexpectedly. Check log: ${WHITE}$LOG_FILE${NC}"
        log "CRITICAL: Script aborted with exit code $exit_code"
    else
        log "SUCCESS: Script completed successfully."
    fi
}
trap cleanup EXIT ERR

# Visual Utilities
hard_clear() {
    printf "\033c"
}

print_banner() {
    echo -e "${MAGENTA}"
    echo " ▄▄▄      ██████╗  ████████╗ ██╗  ██╗"
    echo " ████╗    ██╔══██╗ ██╔═════╝ ██║  ██║"
    echo " ██╔██╗   ██████╔╝ ██║       ███████║"
    echo " ██║╚██╗  ██╔══██╗ ██║       ██╔══██║"
    echo " ██║ ╚██╗ ██║  ██║ ████████╗ ██║  ██║"
    echo " ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚═══════╝ ╚═╝  ╚═╝"
    echo "  >> UNIVERSAL INSTALLER SYSTEM v1.0.0"
    echo -e "${NC}"
}

start_step() {
    local step_num="$1"
    local step_name="$2"
    log "STEP START: $step_num - $step_name"
    hard_clear
    print_banner
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD} STEP $step_num :: $step_name ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}\n"
}

ask_input() {
    local var_name="$1"
    local prompt_text="$2"
    local default_val="${3:-}"
    local input_val
    
    if [[ -n "$default_val" ]]; then
        echo -ne "${YELLOW}${BOLD} ➜ ${NC}${WHITE}$prompt_text${NC} [${DIM}$default_val${NC}]: "
    else
        echo -ne "${YELLOW}${BOLD} ➜ ${NC}${WHITE}$prompt_text${NC}: "
    fi
    read -r input_val
    
    # Logic: Use default if input is empty, otherwise use input
    if [[ -z "$input_val" && -n "$default_val" ]]; then
        printf -v "$var_name" '%s' "$default_val"
    else
        printf -v "$var_name" '%s' "$input_val"
    fi
    log "INPUT: $var_name set to '${!var_name}'"
}

print_menu_grid() {
    local -n arr=$1
    local len=${#arr[@]}
    local half=$(( (len + 1) / 2 ))

    echo -e "${DIM} Available Options:${NC}"
    for (( i=0; i<half; i++ )); do
        val1="${arr[$i]}"
        val2="${arr[$i+half]:-}"
        
        idx1=$((i+1))
        printf "  ${CYAN}%2d)${NC} %-25s" "$idx1" "$val1"
        
        if [[ -n "$val2" ]]; then
            idx2=$((i+half+1))
            printf "  ${CYAN}%2d)${NC} %-25s" "$idx2" "$val2"
        fi
        echo ""
    done
    echo ""
}

show_progress_bar() {
    local pid=$1
    local width=30
    local i=0
    local direction=1
    
    # Hide cursor
    tput civis 2>/dev/null || true
    echo -ne "\n  ${BOLD}Installing:${NC} ["
    
    # Loop while process exists
    while kill -0 "$pid" 2>/dev/null; do
        local bar=""
        for ((j=0; j<width; j++)); do
            if [ $j -eq $i ]; then bar+="<=>"; else bar+=" "; fi
        done
        printf "\r  ${BOLD}Installing:${NC} [${CYAN}%-${width}s${NC}]" "${bar:0:$width}"
        
        i=$((i + direction))
        if [ $i -ge $((width - 3)) ] || [ $i -le 0 ]; then direction=$((direction * -1)); fi
        sleep 0.1
    done
    
    local full_bar=$(printf '=%0.s' $(seq 1 $width))
    printf "\r  ${BOLD}Installing:${NC} [${CYAN}$full_bar${NC}] Done\n"
    sleep 1
    tput cnorm 2>/dev/null || true
}

# --- [3] PRE-FLIGHT CHECKS ----------------------------------------------------

log "INIT: Starting Pre-flight checks"

# 1. Root Check
if [[ $EUID -ne 0 ]]; then
   echo -e "${ICON_ERR} This script must be run as root."
   exit 1
fi

# 2. UEFI Check
if [[ ! -d /sys/firmware/efi ]]; then
    echo -e "\n${ICON_ERR} Critical Error: UEFI environment not detected."
    echo " Please enable UEFI in BIOS and disable CSM/Legacy support."
    exit 1
fi

# 3. Dependency Check
for cmd in sgdisk iwctl pacman awk grep; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${ICON_ERR} Missing dependency: $cmd"
        exit 1
    fi
done

# Initialize Log
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
log "INIT: Pre-flight checks passed. Starting UI."

# ==============================================================================
# SECTION 1: SYSTEM IDENTITY
# ==============================================================================
start_step "1" "SYSTEM IDENTITY CONFIGURATION"

echo -e "${ICON_INF} Configure the network identity for this machine."
ask_input "MY_HOSTNAME" "Enter Hostname" "$HOSTNAME_DEFAULT"
echo -e "${ICON_OK} Hostname set to: ${BOLD}$MY_HOSTNAME${NC}"
sleep 1

# ==============================================================================
# SECTION 2: REGIONAL SETTINGS
# ==============================================================================
start_step "2" "REGIONAL SETTINGS"

# 2.1 Keyboard Layout
echo -e "${ICON_INF} Select Physical Keyboard Layout"
keymaps=("us" "es" "la-latin1" "uk" "de-latin1" "fr" "pt-latin1" "it" "ru" "jp106")
print_menu_grid keymaps

while true; do
    ask_input "K_OPT" "Select Layout Number"
    if [[ "$K_OPT" =~ ^[0-9]+$ ]] && [ "$K_OPT" -ge 1 ] && [ "$K_OPT" -le "${#keymaps[@]}" ]; then
        KEYMAP="${keymaps[$((K_OPT-1))]}"
        echo -e "${ICON_OK} Selected: ${BOLD}$KEYMAP${NC}"
        log "CONFIG: Keymap set to $KEYMAP"
        loadkeys "$KEYMAP" 2>/dev/null || true
        break
    else
        echo -e "${ICON_ERR} Invalid option."
    fi
done

# 2.2 System Locale
echo -e "\n${ICON_INF} Select System Display Language"
locales=("en_US.UTF-8" "es_ES.UTF-8" "es_MX.UTF-8" "fr_FR.UTF-8" "de_DE.UTF-8" "pt_BR.UTF-8" "it_IT.UTF-8" "ru_RU.UTF-8" "ja_JP.UTF-8" "zh_CN.UTF-8")
print_menu_grid locales

while true; do
    ask_input "L_OPT" "Select Language Number"
    if [[ "$L_OPT" =~ ^[0-9]+$ ]] && [ "$L_OPT" -ge 1 ] && [ "$L_OPT" -le "${#locales[@]}" ]; then
        LOCALE="${locales[$((L_OPT-1))]}"
        echo -e "${ICON_OK} Selected: ${BOLD}$LOCALE${NC}"
        log "CONFIG: Locale set to $LOCALE"
        break
    else
        echo -e "${ICON_ERR} Invalid option."
    fi
done

# 2.3 Timezone
echo -e "\n${ICON_INF} Select Timezone Region"
mapfile -t regions < <(cd /usr/share/zoneinfo && find . -maxdepth 1 -type d ! -name . -printf '%P\n' | sort)
print_menu_grid regions

while true; do
    ask_input "R_OPT" "Select Region Number"
    if [[ "$R_OPT" =~ ^[0-9]+$ ]] && [ "$R_OPT" -ge 1 ] && [ "$R_OPT" -le "${#regions[@]}" ]; then
        REGION="${regions[$((R_OPT-1))]}"
        break
    else
        echo -e "${ICON_ERR} Invalid option."
    fi
done

echo -e "\n${ICON_INF} Select City in $REGION"
mapfile -t cities < <(ls "/usr/share/zoneinfo/$REGION")
short_cities=("${cities[@]:0:20}")
print_menu_grid short_cities

while true; do
    ask_input "CITY_INPUT" "Select Number OR Type Name"
    # Allow selection by index or direct string input
    if [[ "$CITY_INPUT" =~ ^[0-9]+$ ]] && [ "$CITY_INPUT" -ge 1 ] && [ "$CITY_INPUT" -le "${#short_cities[@]}" ]; then
        CITY="${short_cities[$((CITY_INPUT-1))]}"
    else
        CITY="$CITY_INPUT"
    fi
    
    if [ -f "/usr/share/zoneinfo/$REGION/$CITY" ]; then
        TIMEZONE="$REGION/$CITY"
        echo -e "${ICON_OK} Timezone set to: ${BOLD}$TIMEZONE${NC}"
        log "CONFIG: Timezone set to $TIMEZONE"
        break
    else
        echo -e "${ICON_ERR} Invalid Timezone: $REGION/$CITY does not exist."
    fi
done
sleep 1

# ==============================================================================
# SECTION 3: NETWORK CONNECTIVITY
# ==============================================================================
start_step "3" "NETWORK CONNECTIVITY CHECK"

check_connection() {
    ping -c 1 archlinux.org &> /dev/null || ping -c 1 google.com &> /dev/null
}

if check_connection; then
    echo -e "${ICON_OK} Internet Connection: ${GREEN}Active${NC}"
    log "NET: Connection active."
else
    echo -e "${ICON_ERR} Internet Connection: ${RED}Offline${NC}"
    echo -e "${DIM}Initializing Wireless Interface...${NC}"
    log "NET: Connection offline. Attempting WiFi scan."
    
    # Robust Interface Detection: Excludes loopback, virtual, ethernet
    WIFI_INTERFACE=$(ip link | awk -F: '$0 !~ "lo|vir|eth|docker" {print $2;getline}' | head -n 1 | tr -d ' ')
    
    if [[ -z "$WIFI_INTERFACE" ]]; then
        echo -e "${ICON_ERR} No Wireless Interface found. Manual configuration required."
        log "NET: No WiFi interface found."
        read -p "Press Enter to continue (shell will spawn on fail)..."
    else
        echo -e "${ICON_INF} Scanning on Interface: ${BOLD}$WIFI_INTERFACE${NC}"
        iwctl station "$WIFI_INTERFACE" scan
        
        echo -e "\n${CYAN}:: Available Networks ::${NC}"
        iwctl station "$WIFI_INTERFACE" get-networks
        echo ""
        
        while true; do
            echo -e "${ICON_ASK} WiFi Authentication Required"
            ask_input "WIFI_SSID" "SSID Name"
            
            echo -ne "${YELLOW}${BOLD} ➜ ${NC}${WHITE}Password${NC}: "
            read -s WIFI_PASS
            echo ""
            
            echo -e "${ICON_INF} Authenticating with ${BOLD}$WIFI_SSID${NC}..."
            iwctl --passphrase "$WIFI_PASS" station "$WIFI_INTERFACE" connect "$WIFI_SSID"
            
            echo -e "${ICON_INF} Verifying Handshake (8s timeout)..."
            sleep 8
            
            if check_connection; then
                echo -e "${ICON_OK} ${GREEN}Connection Established Successfully.${NC}"
                timedatectl set-ntp true
                log "NET: Connected to $WIFI_SSID"
                break
            else
                echo -e "${ICON_ERR} ${RED}Connection Failed.${NC}"
                log "NET: Connection failed to $WIFI_SSID"
            fi
        done
    fi
fi
sleep 1

# ==============================================================================
# SECTION 4: STORAGE ARCHITECTURE
# ==============================================================================
start_step "4" "STORAGE ARCHITECTURE"

echo -e "${ICON_INF} Detected Storage Devices:"
# Robust LSBLK command with error suppression for empty pipes
lsblk -d -n -o NAME,SIZE,MODEL,TYPE | grep 'disk' || true | awk '{print "    • /dev/" $1 " [" $2 "] " $3}'
echo ""

while true; do
    ask_input "DRIVE_INPUT" "Enter Target Drive (e.g. nvme0n1)"
    CLEAN_NAME=${DRIVE_INPUT#/dev/}
    TARGET_DISK="/dev/$CLEAN_NAME"
    
    if lsblk -d "$TARGET_DISK" &>/dev/null; then
        echo -e "${ICON_OK} Target Locked: ${BOLD}$TARGET_DISK${NC}"
        
        # Safety Check: Is the drive currently mounted?
        if lsblk -no MOUNTPOINT "$TARGET_DISK" | grep -q "/"; then
            echo -e "${ICON_WRN} Drive is currently mounted. Unmount it first."
            log "STORAGE: User selected mounted drive $TARGET_DISK. Rejected."
            continue
        fi
        log "STORAGE: Selected target $TARGET_DISK"
        break
    else
        echo -e "${ICON_ERR} Device not found."
    fi
done

echo -e "\n${ICON_INF} Running Hardware Analysis..."
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$(($TOTAL_RAM_KB / 1024 / 1024))
CORES=$(nproc)

echo -e "   [RAM]  Detected ${BOLD}${TOTAL_RAM_GB}GB${NC} System Memory."

# Intelligent Swap Strategy
if [ $TOTAL_RAM_GB -ge 8 ]; then
    echo -e "           -> Strategy: Standard Swapfile (4GB)."
    SWAP_SIZE=4
else
    echo -e "           -> Strategy: ${YELLOW}Low Memory.${NC} Swapfile increased to 8GB."
    SWAP_SIZE=8
fi
log "HARDWARE: RAM=${TOTAL_RAM_GB}GB, Cores=${CORES}, Swap=${SWAP_SIZE}GB"

while true; do
    echo -e "\n${ICON_INF} Select Partitioning Strategy"
    echo -e "  ${CYAN} 1)${NC} Use Free Space (Dual Boot Safe)"
    echo -e "  ${CYAN} 2)${NC} Wipe Entire Disk (Clean Install)"
    echo -e "  ${CYAN} 3)${NC} Manual Mode (Advanced)"
    echo ""

    ask_input "STRATEGY_OPT" "Select Strategy Number"

    ROOT_PART=""
    EFI_PART=""
    FORMAT_EFI="no"

    case $STRATEGY_OPT in
        1)
            # Strategy: Auto-Partition Free Space
            # Pre-requisite: Check if free space actually exists
            if sgdisk -p "$TARGET_DISK" | grep -i "Total free space" | grep -q "0.0 B"; then
                 echo -e "${ICON_ERR} No free space available on disk."
                 log "STORAGE: Free space strategy selected but 0 bytes free."
                 exit 1
            fi
            
            # Create root partition in largest free block
            sgdisk -a 2048 -n 0:0:0 -t 0:8304 -c 0:"Arch Root" "$TARGET_DISK" &>/dev/null
            partprobe "$TARGET_DISK" && sync && sleep 2
            
            # Identify the partition we just created
            ROOT_PART=$(lsblk -n -o PATH,PARTLABEL "$TARGET_DISK" | grep "Arch Root" | tail -n1 | awk '{print $1}')
            
            if [[ -z "$ROOT_PART" ]]; then
                 echo -e "${ICON_WRN} Auto-detect needs confirmation."
                 lsblk "$TARGET_DISK" -o NAME,SIZE,TYPE,LABEL
                 ask_input "ROOT_INPUT" "Identify the new Partition (e.g. nvme0n1p3)"
                 ROOT_PART="/dev/${ROOT_INPUT#/dev/}"
            else
                 echo -e "${ICON_OK} Auto-Detected New Partition: ${BOLD}$ROOT_PART${NC}"
            fi
            
            # Detect existing EFI partition using GUID (Enterprise Standard)
            mapfile -t EFI_LIST < <(lsblk -n -o PATH,PARTTYPE "$TARGET_DISK" | grep -i 'c12a7328-f81f-11d2-ba4b-00a0c93ec93b' | awk '{print $1}')
            
            if [ ${#EFI_LIST[@]} -eq 1 ]; then
                EFI_PART=${EFI_LIST[0]}
                echo -e "${ICON_OK} Detected EFI System at ${BOLD}$EFI_PART${NC}"
            elif [ ${#EFI_LIST[@]} -eq 0 ]; then
                echo -e "${ICON_ERR} No EFI Partition found. System requires EFI."
                exit 1
            else
                echo -e "${ICON_WRN} Multiple EFI Partitions found. Please select one:"
                for i in "${!EFI_LIST[@]}"; do echo "  $((i+1))) ${EFI_LIST[$i]}"; done
                ask_input "EFI_IDX" "Select EFI Partition Number"
                EFI_PART=${EFI_LIST[$((EFI_IDX-1))]}
            fi
            
            FORMAT_EFI="no"
            log "STORAGE: Strategy 1 (Free Space). Root: $ROOT_PART, EFI: $EFI_PART"
            break
            ;;
        2)
            # Strategy: Wipe and Clean
            echo -e "\n${RED}${BOLD}CRITICAL WARNING: THIS WILL DESTROY ALL DATA ON $TARGET_DISK${NC}"
            ask_input "CONFIRM" "Type 'DESTROY' to confirm"
            [[ "$CONFIRM" != "DESTROY" ]] && echo "Aborted." && exit 1
            
            # Zap disk and create standard partition layout
            sgdisk -Z "$TARGET_DISK" &>/dev/null
            sgdisk -a 2048 -n 1:0:+512M -t 1:ef00 -c 1:"EFI System" "$TARGET_DISK" &>/dev/null
            sgdisk -a 2048 -n 2:0:0     -t 2:8304 -c 2:"Arch Root"  "$TARGET_DISK" &>/dev/null
            partprobe "$TARGET_DISK" && sync && sleep 3
            
            if [[ "$TARGET_DISK" == *"nvme"* ]]; then
                EFI_PART="${TARGET_DISK}p1"; ROOT_PART="${TARGET_DISK}p2"
            else
                EFI_PART="${TARGET_DISK}1"; ROOT_PART="${TARGET_DISK}2"
            fi
            FORMAT_EFI="yes"
            log "STORAGE: Strategy 2 (Wipe). Root: $ROOT_PART, EFI: $EFI_PART"
            break
            ;;
        3)
            # Strategy: Manual
            echo -e "${ICON_INF} Launching cfdisk..."
            read -p "Press Enter to continue..."
            cfdisk "$TARGET_DISK"
            partprobe "$TARGET_DISK" && sync && sleep 3
            
            echo -e "\n${CYAN}:: Partition Map ::${NC}"
            lsblk "$TARGET_DISK" -o NAME,SIZE,TYPE,FSTYPE,LABEL
            
            ask_input "E_IN" "Select EFI Partition"
            EFI_PART="/dev/${E_IN#/dev/}"
            ask_input "FORMAT_EFI" "Format EFI? (yes/no)"
            
            if [[ "$FORMAT_EFI" == "yes" ]]; then
                echo -e "${YELLOW}WARNING: Formatting EFI will delete all other bootloaders!${NC}"
                ask_input "EFI_CONFIRM" "Are you sure?"
                [[ "$EFI_CONFIRM" != "yes" ]] && FORMAT_EFI="no"
            fi
            
            ask_input "R_IN" "Select Root Partition"
            ROOT_PART="/dev/${R_IN#/dev/}"
            log "STORAGE: Strategy 3 (Manual). Root: $ROOT_PART, EFI: $EFI_PART"
            break
            ;;
        *)
            echo "Invalid Option." ;;
    esac
done

echo -e "\n${GREEN}=== CONFIGURATION SUMMARY ===${NC}"
echo -e " Target Disk : ${WHITE}$TARGET_DISK${NC}"
echo -e " EFI Boot    : ${WHITE}$EFI_PART${NC} (Format: $FORMAT_EFI)"
echo -e " System Root : ${WHITE}$ROOT_PART${NC} (Format: YES)"
echo -e " Swap Size   : ${WHITE}${SWAP_SIZE}GB${NC}"
echo -e "${GREEN}=============================${NC}"

ask_input "CONFIRM" "Type 'yes' to proceed with installation"
[[ "$CONFIRM" != "yes" ]] && exit 1

# ==============================================================================
# SECTION 5: INSTALLATION EXECUTION
# ==============================================================================
start_step "5" "CORE INSTALLATION"

if ! check_connection; then
    echo -e "${ICON_ERR} Connection lost. Cannot proceed."
    log "INSTALL: Connection lost immediately before pacstrap."
    exit 1
fi

DISK_MODIFIED=1

echo -e "${ICON_INF} Optimizing Pacman (Parallel Downloads)..."
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

echo -e "${ICON_INF} Formatting Filesystems..."
mkfs.ext4 -F "$ROOT_PART" &>/dev/null
if [[ "$FORMAT_EFI" == "yes" ]]; then
    mkfs.vfat -F32 "$EFI_PART" &>/dev/null
fi

echo -e "${ICON_INF} Mounting Partitions..."
mount "$ROOT_PART" "$MOUNT_POINT"
mkdir -p "$MOUNT_POINT/boot/efi"
mount "$EFI_PART" "$MOUNT_POINT/boot/efi"

echo -e "${ICON_INF} Detecting CPU Microcode..."
if grep -q "AuthenticAMD" /proc/cpuinfo; then
    UCODE="amd-ucode"
    echo -e "${ICON_OK} AMD CPU Detected."
else
    UCODE="intel-ucode"
    echo -e "${ICON_OK} Intel CPU Detected."
fi
log "INSTALL: Microcode set to $UCODE"

echo -e "${ICON_INF} Installing Base System (Zen Kernel)..."
echo -e "${DIM} (Logs available at $LOG_FILE)${NC}"

# Replace ucode placeholder in package list
FINAL_PACKAGES=("${BASE_PACKAGES[@]}" "$UCODE")

# Execute pacstrap in background with PID tracking
pacstrap "$MOUNT_POINT" "${FINAL_PACKAGES[@]}" &>> "$LOG_FILE" &
INSTALL_PID=$!

sleep 1
if ! kill -0 $INSTALL_PID 2>/dev/null; then
    echo -e "\n${ICON_ERR} Pacstrap failed immediately. Check $LOG_FILE"
    exit 1
fi

show_progress_bar $INSTALL_PID
wait $INSTALL_PID
if [ $? -ne 0 ]; then
    echo -e "\n${ICON_ERR} Installation Failed. Check $LOG_FILE"
    exit 1
fi

echo -e "${ICON_INF} Generating fstab..."
genfstab -U "$MOUNT_POINT" >> "$MOUNT_POINT/etc/fstab"

# ==============================================================================
# SECTION 6: SYSTEM CONFIGURATION (CHROOT)
# ==============================================================================
start_step "6" "USER & SYSTEM CONFIGURATION"

while true; do
    ask_input "MY_USER" "Enter Desired Username"
    if [[ "$MY_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then break; else echo -e "${ICON_ERR} Invalid format."; fi
done

while true; do
    echo -ne "${YELLOW}${BOLD} ➜ ${NC}${WHITE}Password${NC}: "
    read -s P1; echo
    echo -ne "${YELLOW}${BOLD} ➜ ${NC}${WHITE}Confirm Password${NC}: "
    read -s P2; echo
    [[ "$P1" == "$P2" && -n "$P1" ]] && MY_PASS="$P1" && break
    echo -e "${ICON_ERR} Passwords do not match."
done

# Export variables required for the chroot environment
export SWAP_SIZE CORES MY_HOSTNAME LOCALE KEYMAP TIMEZONE MY_USER MY_PASS

echo ""
echo -e "${ICON_INF} Configuring System Internals..."

# Begin Chroot Operations
arch-chroot "$MOUNT_POINT" /bin/bash <<EOF
set -euo pipefail

# 1. Localization
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc &>/dev/null
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen &>/dev/null
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$MY_HOSTNAME" > /etc/hostname

# 2. User & Security
echo "root:$MY_PASS" | chpasswd
# Create user only if it doesn't exist (idempotency)
if ! id "$MY_USER" &>/dev/null; then
    useradd -m -G wheel,storage,power,video -s /bin/bash "$MY_USER"
fi
echo "$MY_USER:$MY_PASS" | chpasswd
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/00_arch_installer
chmod 440 /etc/sudoers.d/00_arch_installer

# 3. Bootloader (GRUB)
pacman -S --noconfirm grub efibootmgr os-prober &>/dev/null
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
# Ensure directory exists
mkdir -p /boot/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch &>/dev/null
grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null

# 4. Services
systemctl enable NetworkManager power-profiles-daemon bluetooth fstrim.timer &>/dev/null

# 5. Compilation Optimization
sed -i "s/^#MAKEFLAGS=.*/MAKEFLAGS=\"-j$CORES\"/" /etc/makepkg.conf 2>/dev/null || true

# 6. Swap Configuration
if [ ! -f /swapfile ]; then
    dd if=/dev/zero of=/swapfile bs=1G count=$SWAP_SIZE status=none
    chmod 600 /swapfile
    mkswap /swapfile &>/dev/null
fi
swapon /swapfile &>/dev/null
if ! grep -q "/swapfile" /etc/fstab; then
    echo "/swapfile none swap defaults 0 0" >> /etc/fstab
fi

# 7. Quality of Life (Nano)
mkdir -p "/home/$MY_USER"
echo "set tabsize 4" > "/home/$MY_USER/.nanorc"
echo "set tabstospaces" >> "/home/$MY_USER/.nanorc"
chown "$MY_USER:$MY_USER" "/home/$MY_USER/.nanorc"

EOF
# End Chroot

# Security Cleanup
unset MY_PASS P1 P2
history -c
DISK_MODIFIED=0

# ==============================================================================
# FINALIZATION
# ==============================================================================
hard_clear
print_banner
echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}${BOLD}    INSTALLATION SUCCESSFUL v3.0.0 ${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}"
echo -e ""
echo -e " 1. Remove installation media."
echo -e " 2. Type ${BOLD}reboot${NC} to start your new system."
echo -e " 3. Login as: ${BOLD}$MY_USER${NC}"
echo -e ""
echo -e "${DIM} Welcome to the Arch Linux family.${NC}"
echo -e "${DIM} Install Log: $LOG_FILE${NC}"
echo -e ""

log "SUCCESS: Installation sequence completed."

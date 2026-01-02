#!/bin/bash

# ==============================================================================
#  ARCH LINUX UNIVERSAL INSTALLER v2.8.0
#  Zen Kernel | Strict Mode | Dry-Run Capable | Edge-Case Hardened
# ==============================================================================

# --- [0] PRE-FLIGHT ARGUMENTS & CONFIG ----------------------------------------
set -u # Undefined variables are errors
set -o pipefail # Pipes fail if any command fails

# 1.1 Polish: Dry-run / simulation mode
DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
fi

# 1.2 Polish: Logging (files + stdout)
LOG_FILE="/tmp/arch-installer.log"
# Ensure log file exists and we can write to it
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

# 1.6 Polish: Color disable fallback
if [[ -t 1 ]] && command -v tput &>/dev/null && [[ $(tput colors) -ge 8 ]]; then
    NC='\033[0m'
    BOLD='\033[1m'
    MAGENTA='\033[1;35m'
    CYAN='\033[1;36m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    RED='\033[1;31m'
    WHITE='\033[1;37m'
    DIM='\033[2m'
else
    NC=""; BOLD=""; MAGENTA=""; CYAN=""; GREEN=""; YELLOW=""; RED=""; WHITE=""; DIM=""
fi

ICON_OK="[${GREEN}  OK  ${NC}]"
ICON_ERR="[${RED} FAIL ${NC}]"
ICON_WRN="[${YELLOW} WARN ${NC}]"
ICON_ASK="[${MAGENTA}  ??  ${NC}]"
ICON_INF="[${CYAN} INFO ${NC}]"
ICON_DRY="[${MAGENTA} DRY  ${NC}]"

# 1.3 Polish: Clearer fatal error helper
fatal() {
    echo -e "\n${ICON_ERR} ${BOLD}CRITICAL ERROR:${NC} $1"
    echo -e "${DIM} See $LOG_FILE for details.${NC}"
    exit 1
}

# Wrapper for destructive commands
run_safe() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "${ICON_DRY} Would run: $*"
    else
        eval "$@"
    fi
}

# 17. Edge-Case: ARM/Non-x86 detection
if [[ "$(uname -m)" != "x86_64" ]]; then
    fatal "This script is optimized for x86_64 architecture only."
fi

# Check for UEFI Boot Mode
if [[ ! -d /sys/firmware/efi ]]; then
    fatal "This script requires a UEFI boot environment."
fi

# 2.5 Edge-Case: Secure Boot Warning
if command -v mokutil &>/dev/null; then
    if mokutil --sb-state 2>/dev/null | grep -q "enabled"; then
        echo -e "${ICON_WRN} ${YELLOW}Secure Boot is ENABLED.${NC} GRUB may require manual signing."
        sleep 2
    fi
fi

# Global State for Trap
DISK_MODIFIED=0

cleanup() {
    tput cnorm 2>/dev/null || true
    if [[ "$DISK_MODIFIED" -eq 1 ]]; then
        echo -e "\n${ICON_WRN} Script stopped after disk modification."
        echo -e "${DIM} The system may be in a partial state.${NC}"
    fi
}
# 1.7 Polish: Trap SIGINT separately
trap 'echo -e "\n${ICON_WRN} Interrupted by user."; exit 130' SIGINT
trap cleanup EXIT ERR

# --- [1] UI UTILITIES ---------------------------------------------------------
function hard_clear {
    printf "\033c"
}

function print_banner {
    echo -e "${MAGENTA}"
    echo " ▄▄▄        ██████╗  ████████╗ ██╗  ██╗"
    echo " ████╗      ██╔══██╗ ██╔═════╝ ██║  ██║"
    echo " ██╔██╗     ██████╔╝ ██║        ███████║"
    echo " ██║╚██╗    ██╔══██╗ ██║        ██╔══██║"
    echo " ██║ ╚██╗   ██║  ██║ ████████╗ ██║  ██║"
    echo " ╚═╝  ╚═╝   ╚═╝  ╚═╝ ╚═══════╝ ╚═╝  ╚═╝"
    echo "  >> UNIVERSAL INSTALLER SYSTEM v2.8.0"
    echo "  >> ZEN KERNEL + ARCH STANDARDS"
    echo -e "${NC}"
    
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "${YELLOW}${BOLD}  :: DRY RUN MODE ACTIVE - NO DISK CHANGES ::${NC}"
    fi
}

function start_step {
    hard_clear
    print_banner
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD} STEP $1 :: $2 ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}\n"
}

function ask_input {
    local var_name="$1"
    local prompt_text="$2"
    local default_val="${3:-}"
    
    if [[ -n "$default_val" ]]; then
        echo -ne "${YELLOW}${BOLD} ➜ ${NC}${WHITE}$prompt_text${NC} [${DIM}$default_val${NC}]: "
    else
        echo -ne "${YELLOW}${BOLD} ➜ ${NC}${WHITE}$prompt_text${NC}: "
    fi
    read -r input_val
    
    if [[ -z "$input_val" && -n "$default_val" ]]; then
        printf -v "$var_name" '%s' "$default_val"
    else
        printf -v "$var_name" '%s' "$input_val"
    fi
}

function print_menu_grid {
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

function show_progress_bar {
    local pid=$1
    local width=30
    local i=0
    local direction=1
    
    tput civis 2>/dev/null || true
    echo -ne "\n  ${BOLD}Installing:${NC} ["
    
    while ps -p "$pid" > /dev/null; do
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

# ==============================================================================
# SECTION 1: SYSTEM IDENTITY
# ==============================================================================
start_step "1" "SYSTEM IDENTITY CONFIGURATION"

echo -e "${ICON_INF} Configure the network identity for this machine."
ask_input "MY_HOSTNAME" "Enter Hostname" "arch-linux"
echo -e "${ICON_OK} Hostname set to: ${BOLD}$MY_HOSTNAME${NC}"
sleep 1

# ==============================================================================
# SECTION 2: INPUT & REGION
# ==============================================================================
start_step "2" "REGIONAL SETTINGS"

# 2.1 Keyboard
echo -e "${ICON_INF} Select Physical Keyboard Layout"
keymaps=("us" "es" "la-latin1" "uk" "de-latin1" "fr" "pt-latin1" "it" "ru" "jp106")
print_menu_grid keymaps

while true; do
    ask_input "K_OPT" "Select Layout Number"
    if [[ "$K_OPT" =~ ^[0-9]+$ ]] && [ "$K_OPT" -ge 1 ] && [ "$K_OPT" -le "${#keymaps[@]}" ]; then
        KEYMAP="${keymaps[$((K_OPT-1))]}"
        break
    else
        echo -e "${ICON_ERR} Invalid option."
    fi
done

# 2.2 Locale
echo -e "\n${ICON_INF} Select System Display Language"
locales=("en_US.UTF-8" "es_ES.UTF-8" "es_MX.UTF-8" "fr_FR.UTF-8" "de_DE.UTF-8" "pt_BR.UTF-8" "it_IT.UTF-8" "ru_RU.UTF-8" "ja_JP.UTF-8" "zh_CN.UTF-8")
print_menu_grid locales

while true; do
    ask_input "L_OPT" "Select Language Number"
    if [[ "$L_OPT" =~ ^[0-9]+$ ]] && [ "$L_OPT" -ge 1 ] && [ "$L_OPT" -le "${#locales[@]}" ]; then
        LOCALE="${locales[$((L_OPT-1))]}"
        # 12. Edge-Case: Locale Validation
        if ! grep -q "$LOCALE" /usr/share/i18n/SUPPORTED; then
            echo -e "${ICON_WRN} Locale $LOCALE not found in supported list. Proceeding anyway."
        fi
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
short_cities=("${cities[@]:0:20}") # Limit to top 20 to prevent scrolling overflow
print_menu_grid short_cities

while true; do
    ask_input "CITY_INPUT" "Select Number OR Type Name"
    if [[ "$CITY_INPUT" =~ ^[0-9]+$ ]] && [ "$CITY_INPUT" -ge 1 ] && [ "$CITY_INPUT" -le "${#short_cities[@]}" ]; then
        CITY="${short_cities[$((CITY_INPUT-1))]}"
    else
        CITY="$CITY_INPUT"
    fi
    
    if [ -f "/usr/share/zoneinfo/$REGION/$CITY" ]; then
        TIMEZONE="$REGION/$CITY"
        timedatectl set-ntp true
        break
    else
        echo -e "${ICON_ERR} Invalid Timezone."
    fi
done
sleep 1

# ==============================================================================
# SECTION 3: NETWORK CONNECTIVITY
# ==============================================================================
start_step "3" "NETWORK CONNECTIVITY CHECK"

# 2.2 Edge-Case: IPv6 Fallback
check_internet() {
    ping -c 1 google.com &>/dev/null || ping -6 -c 1 google.com &>/dev/null
}

if check_internet || true; then
    if check_internet; then
        echo -e "${ICON_OK} Internet Connection: ${GREEN}Active${NC}"
    else
        echo -e "${ICON_ERR} Internet Connection: ${RED}Offline${NC}"
        
        # 2.2 Edge-Case: Check if iwctl exists
        if ! command -v iwctl &>/dev/null; then
            fatal "iwctl not found. Cannot configure WiFi."
        fi

        WIFI_INTERFACE=$(ip link | awk -F: '$0 !~ "lo|vir|eth" {print $2;getline}' | head -n 1 | tr -d ' ')
        
        if [[ -z "$WIFI_INTERFACE" ]]; then
            echo -e "${ICON_ERR} No Wireless Interface found."
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
                
                iwctl --passphrase "$WIFI_PASS" station "$WIFI_INTERFACE" connect "$WIFI_SSID"
                sleep 8
                
                if check_internet; then
                    echo -e "${ICON_OK} ${GREEN}Connection Established.${NC}"
                    timedatectl set-ntp true
                    break
                else
                    echo -e "${ICON_ERR} ${RED}Connection Failed.${NC}"
                fi
            done
        fi
    fi
fi

# 2.2 Edge-Case: Captive Portal Check
if ! curl -I https://archlinux.org &>/dev/null; then
    echo -e "${ICON_WRN} HTTP check failed. You may be behind a captive portal."
fi

# 2.7 Edge-Case: Update Keyring before doing anything else
echo -e "${ICON_INF} Updating Arch Keyring (Prevents signature errors)..."
if [[ "$DRY_RUN" -eq 0 ]]; then
    pacman -Sy --noconfirm archlinux-keyring &>/dev/null || echo -e "${ICON_WRN} Keyring update failed."
fi

# 14. Edge-Case: Slow mirrors
echo -e "${ICON_INF} Optimizing Mirrorlist..."
if [[ "$DRY_RUN" -eq 0 ]]; then
    reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist --protocol https --download-timeout 5 &>/dev/null || echo -e "${ICON_WRN} Reflector failed, using default mirrors."
fi
sleep 1

# ==============================================================================
# SECTION 4: STORAGE CONFIGURATION
# ==============================================================================
start_step "4" "STORAGE ARCHITECTURE"

echo -e "${ICON_INF} Detected Storage Devices:"
lsblk -d -n -o NAME,SIZE,MODEL,TYPE | grep 'disk' || true | awk '{print "    • /dev/" $1 " [" $2 "] " $3}'
echo ""

while true; do
    ask_input "DRIVE_INPUT" "Enter Target Drive (e.g. nvme0n1)"
    CLEAN_NAME=${DRIVE_INPUT#/dev/}
    TARGET_DISK="/dev/$CLEAN_NAME"
    
    if lsblk -d "$TARGET_DISK" &>/dev/null; then
        echo -e "${ICON_OK} Target Locked: ${BOLD}$TARGET_DISK${NC}"
        
        # 2.1 Edge-Case: Drive is mounted
        if lsblk -no MOUNTPOINT "$TARGET_DISK" | grep -q "/"; then
            echo -e "${ICON_ERR} Drive is currently mounted. Unmount it first."
            continue
        fi

        # 2.1 Edge-Case: LVM or LUKS detection
        if lsblk -no TYPE "$TARGET_DISK" | grep -E "lvm|crypt" &>/dev/null; then
            echo -e "${ICON_WRN} LVM or Encryption detected. Automatic partitioning might fail."
            ask_input "LVM_CONF" "Continue anyway? (yes/no)"
            [[ "$LVM_CONF" != "yes" ]] && continue
        fi

        # 19. Edge-Case: Small disk
        DISK_SIZE_BYTES=$(lsblk -dn -o SIZE -b "$TARGET_DISK")
        if (( DISK_SIZE_BYTES < 20*1024*1024*1024 )); then
            echo -e "${ICON_WRN} Disk < 20GB. Installation may be tight."
        fi
        break
    else
        echo -e "${ICON_ERR} Device not found."
    fi
done

echo -e "\n${ICON_INF} Running Hardware Analysis..."
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$(($TOTAL_RAM_KB / 1024 / 1024))
CORES=$(nproc)

if [ $TOTAL_RAM_GB -ge 8 ]; then
    SWAP_SIZE=4
else
    SWAP_SIZE=8
fi

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
            # 1.5 Polish: OS Warning via fdisk output presence
            if fdisk -l "$TARGET_DISK" | grep -E "NTFS|ext4|btrfs" &>/dev/null; then
                 echo -e "${ICON_WRN} Existing OS/Data detected on disk."
            fi

            if sgdisk -p "$TARGET_DISK" | grep -i "Total free space" | grep -q "0.0 B"; then
                 echo -e "${ICON_ERR} No free space available."
                 exit 1
            fi
            
            # 2.1 Edge-Case: Alignment (-a 2048)
            run_safe sgdisk -a 2048 -n 0:0:0 -t 0:8304 -c 0:"Arch Root" "$TARGET_DISK"
            [[ "$DRY_RUN" -eq 0 ]] && { partprobe "$TARGET_DISK" && sync && sleep 2; }
            
            ROOT_PART=$(lsblk -n -o PATH,PARTLABEL "$TARGET_DISK" | grep "Arch Root" | tail -n1 | awk '{print $1}')
            
            if [[ -z "$ROOT_PART" && "$DRY_RUN" -eq 0 ]]; then
                 echo -e "${ICON_WRN} Auto-detect needs confirmation."
                 lsblk "$TARGET_DISK" -o NAME,SIZE,TYPE,LABEL
                 ask_input "ROOT_INPUT" "Identify the new Partition (e.g. nvme0n1p3)"
                 ROOT_PART="/dev/${ROOT_INPUT#/dev/}"
            elif [[ "$DRY_RUN" -eq 1 ]]; then
                 ROOT_PART="${TARGET_DISK}pX"
            fi
            
            # 10. Edge-Case: Multiple EFI detection
            mapfile -t EFI_LIST < <(fdisk -l | grep 'EFI System' | awk '{print $1}')
            
            if [ ${#EFI_LIST[@]} -eq 0 ]; then
                fatal "No EFI Partition found."
            elif [ ${#EFI_LIST[@]} -eq 1 ]; then
                EFI_PART=${EFI_LIST[0]}
            else
                echo -e "${ICON_WRN} Multiple EFI Partitions:"
                for i in "${!EFI_LIST[@]}"; do echo "  $((i+1))) ${EFI_LIST[$i]}"; done
                ask_input "EFI_IDX" "Select EFI Partition Number"
                EFI_PART=${EFI_LIST[$((EFI_IDX-1))]}
            fi
            FORMAT_EFI="no"
            ;;
        2)
            echo -e "\n${RED}${BOLD}CRITICAL WARNING: THIS WILL DESTROY ALL DATA ON $TARGET_DISK${NC}"
            ask_input "CONFIRM" "Type 'DESTROY' to confirm"
            [[ "$CONFIRM" != "DESTROY" ]] && echo "Aborted." && exit 1
            
            # 2.1 Edge-Case: Alignment
            run_safe sgdisk -Z "$TARGET_DISK"
            run_safe sgdisk -a 2048 -n 1:0:+512M -t 1:ef00 -c 1:"EFI System" "$TARGET_DISK"
            run_safe sgdisk -a 2048 -n 2:0:0     -t 2:8304 -c 2:"Arch Root"  "$TARGET_DISK"
            [[ "$DRY_RUN" -eq 0 ]] && { partprobe "$TARGET_DISK" && sync && sleep 3; }
            
            if [[ "$TARGET_DISK" == *"nvme"* ]]; then
                EFI_PART="${TARGET_DISK}p1"; ROOT_PART="${TARGET_DISK}p2"
            else
                EFI_PART="${TARGET_DISK}1"; ROOT_PART="${TARGET_DISK}2"
            fi
            FORMAT_EFI="yes"
            break
            ;;
        3)
            echo -e "${ICON_INF} Launching cfdisk..."
            read -p "Press Enter to continue..."
            run_safe cfdisk "$TARGET_DISK"
            [[ "$DRY_RUN" -eq 0 ]] && { partprobe "$TARGET_DISK" && sync && sleep 3; }
            
            echo -e "\n${CYAN}:: Partition Map ::${NC}"
            lsblk "$TARGET_DISK" -o NAME,SIZE,TYPE,FSTYPE,LABEL
            
            ask_input "E_IN" "Select EFI Partition"
            EFI_PART="/dev/${E_IN#/dev/}"
            ask_input "FORMAT_EFI" "Format EFI? (yes/no)"
            [[ "$FORMAT_EFI" == "yes" ]] && echo -e "${YELLOW}WARNING: Deletes other bootloaders.${NC}"
            
            ask_input "R_IN" "Select Root Partition"
            ROOT_PART="/dev/${R_IN#/dev/}"
            break
            ;;
        *) echo "Invalid Option." ;;
    esac
done

echo -e "\n${GREEN}=== CONFIGURATION SUMMARY ===${NC}"
DISK_MODEL=$(lsblk -dn -o MODEL "$TARGET_DISK")
echo -e " Target Disk : ${WHITE}$TARGET_DISK ($DISK_MODEL)${NC}"
echo -e " EFI Boot    : ${WHITE}$EFI_PART${NC} (Format: $FORMAT_EFI)"
echo -e " System Root : ${WHITE}$ROOT_PART${NC}"
echo -e " Swap Strategy: ${WHITE}${SWAP_SIZE}GB${NC}"
echo -e "${GREEN}=============================${NC}"

# 1.4 Polish: Final confirmation timeout
echo -e "\n${RED}${BOLD}Proceeding in 10 seconds... Ctrl+C to abort.${NC}"
for i in {10..1}; do echo -ne "\rStarting in $i... "; sleep 1; done; echo ""

# ==============================================================================
# SECTION 5: INSTALLATION PROCESS
# ==============================================================================
start_step "5" "CORE INSTALLATION"

if ! check_internet; then fatal "Connection lost."; fi
if [[ "$DRY_RUN" -eq 1 ]]; then echo -e "${ICON_DRY} Stopping before destructive actions."; exit 0; fi

DISK_MODIFIED=1

echo -e "${ICON_INF} Optimizing Pacman..."
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

echo -e "${ICON_INF} Formatting Filesystems..."
mkfs.ext4 -F "$ROOT_PART" &>/dev/null
if [[ "$FORMAT_EFI" == "yes" ]]; then
    mkfs.vfat -F32 "$EFI_PART" &>/dev/null
fi

echo -e "${ICON_INF} Mounting..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot/efi
mount "$EFI_PART" /mnt/boot/efi

echo -e "${ICON_INF} Detecting CPU..."
if grep -q "AuthenticAMD" /proc/cpuinfo; then UCODE="amd-ucode"; else UCODE="intel-ucode"; fi

echo -e "${ICON_INF} Installing Base System..."
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware base-devel \
    "$UCODE" mesa pipewire pipewire-alsa pipewire-pulse wireplumber \
    networkmanager bluez bluez-utils power-profiles-daemon \
    git nano ntfs-3g dosfstools mtools &> /tmp/arch-install.log &

INSTALL_PID=$!
sleep 1
if ! ps -p $INSTALL_PID > /dev/null; then fatal "Pacstrap failed. Check /tmp/arch-install.log"; fi
show_progress_bar $INSTALL_PID
wait $INSTALL_PID || fatal "Installation Failed."

echo -e "${ICON_INF} Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

cat > /mnt/etc/arch-installer.conf <<EOF
INSTALL_DATE=$(date)
HOSTNAME=$MY_HOSTNAME
LOCALE=$LOCALE
TIMEZONE=$TIMEZONE
EOF

# ==============================================================================
# SECTION 6: SYSTEM CONFIGURATION
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

export SWAP_SIZE CORES

arch-chroot /mnt /bin/bash <<EOF
set -euo pipefail
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc &>/dev/null

# 2.3 Edge-Case: Duplicate locale check
grep -q "^$LOCALE UTF-8" /etc/locale.gen || echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen &>/dev/null
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$MY_HOSTNAME" > /etc/hostname

echo "root:$MY_PASS" | chpasswd
useradd -m -G wheel,storage,power,video -s /bin/bash "$MY_USER" || echo "User exists, skipping."
echo "$MY_USER:$MY_PASS" | chpasswd

echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/00_arch_installer
chmod 440 /etc/sudoers.d/00_arch_installer

pacman -S --noconfirm grub efibootmgr os-prober &>/dev/null
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub

sync; sleep 2
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch &>/dev/null
grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null

systemctl enable NetworkManager power-profiles-daemon bluetooth fstrim.timer &>/dev/null

if grep -q '^#MAKEFLAGS' /etc/makepkg.conf; then
    sed -i "s/^#MAKEFLAGS=.*/MAKEFLAGS=\"-j$CORES\"/" /etc/makepkg.conf
elif grep -q '^MAKEFLAGS' /etc/makepkg.conf; then
    sed -i "s/^MAKEFLAGS=.*/MAKEFLAGS=\"-j$CORES\"/" /etc/makepkg.conf
else
    echo "MAKEFLAGS=\"-j$CORES\"" >> /etc/makepkg.conf
fi

# 2.6 Edge-Case: Btrfs Swap check
FS_TYPE=\$(findmnt -n -o FSTYPE /)
if [[ "\$FS_TYPE" == "btrfs" ]]; then
    echo "Filesystem is Btrfs. Skipping swapfile (requires NOCOW setup)."
else
    if [ ! -f /swapfile ]; then
        dd if=/dev/zero of=/swapfile bs=1G count=$SWAP_SIZE status=none
        chmod 600 /swapfile
        mkswap /swapfile &>/dev/null
    fi
    swapon /swapfile &>/dev/null
    grep -q '^/swapfile' /etc/fstab || echo "/swapfile none swap defaults 0 0" >> /etc/fstab
fi
EOF

unset MY_PASS P1 P2
DISK_MODIFIED=0

hard_clear
print_banner
echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}${BOLD}    INSTALLATION SUCCESSFUL v2.8.0 ${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}"
echo -e "\n 1. Type ${BOLD}reboot${NC} to start your new system."
echo -e " 2. Login as: ${BOLD}$MY_USER${NC}\n"

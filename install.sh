#!/bin/bash

# ==============================================================================
#  ARCH LINUX UNIVERSAL INSTALLER v2.0.0
#  v1.9 Aesthetics | v1.5 Stability (Classic Engine)
# ==============================================================================

# --- [1] VISUAL LIBRARY -------------------------------------------------------
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

# --- [2] UI UTILITIES ---------------------------------------------------------
function hard_clear {
    printf "\033c"
}

function print_banner {
    echo -e "${MAGENTA}"
    echo " ▄▄▄      ██████╗  ███████╗ ██╗  ██╗"
    echo " ████╗    ██╔══██╗ ██╔════╝ ██║  ██║"
    echo " ██╔██╗   ██████╔╝ ██║      ███████║"
    echo " ██║╚██╗  ██╔══██╗ ██║      ██╔══██║"
    echo " ██║ ╚██╗ ██║  ██║ ███████╗ ██║  ██║"
    echo " ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚══════╝ ╚═╝  ╚═╝"
    echo "  >> UNIVERSAL INSTALLER SYSTEM v2.0.0"
    echo -e "${NC}"
}

function start_step {
    hard_clear
    print_banner
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD} STEP $1 :: $2 ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}\n"
}

function ask_input {
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

function print_menu_grid {
    local -n arr=$1
    local len=${#arr[@]}
    local half=$(( (len + 1) / 2 ))

    echo -e "${DIM} Available Options:${NC}"
    for (( i=0; i<half; i++ )); do
        val1="${arr[$i]}"
        val2="${arr[$i+half]}"
        
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
        echo -e "${ICON_OK} Selected: ${BOLD}$KEYMAP${NC}"
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
        echo -e "${ICON_OK} Selected: ${BOLD}$LOCALE${NC}"
        break
    else
        echo -e "${ICON_ERR} Invalid option."
    fi
done

# 2.3 Timezone
echo -e "\n${ICON_INF} Select Timezone Region"
# Grep excludes base dir to avoid empty option 1
mapfile -t regions < <(find /usr/share/zoneinfo -maxdepth 1 -type d | cut -d/ -f5 | grep -vE "posix|right|Etc|SystemV|iso3166|Arctic|Antarctica|^$")
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
mapfile -t cities < <(ls /usr/share/zoneinfo/$REGION)
short_cities=("${cities[@]:0:20}")
print_menu_grid short_cities

ask_input "CITY_INPUT" "Select Number OR Type Name"
if [[ "$CITY_INPUT" =~ ^[0-9]+$ ]] && [ "$CITY_INPUT" -ge 1 ] && [ "$CITY_INPUT" -le "${#short_cities[@]}" ]; then
    CITY="${short_cities[$((CITY_INPUT-1))]}"
else
    CITY="$CITY_INPUT"
fi

TIMEZONE="$REGION/$CITY"
echo -e "${ICON_OK} Timezone set to: ${BOLD}$TIMEZONE${NC}"
sleep 1

# ==============================================================================
# SECTION 3: NETWORK CONNECTIVITY
# ==============================================================================
start_step "3" "NETWORK CONNECTIVITY CHECK"

if ping -c 1 google.com &> /dev/null; then
    echo -e "${ICON_OK} Internet Connection: ${GREEN}Active${NC}"
else
    echo -e "${ICON_ERR} Internet Connection: ${RED}Offline${NC}"
    echo -e "${DIM}Initializing Wireless Interface...${NC}"
    
    WIFI_INTERFACE=$(ip link | awk -F: '$0 !~ "lo|vir|eth" {print $2;getline}' | head -n 1 | tr -d ' ')
    
    echo -e "${ICON_INF} Scanning on Interface: ${BOLD}$WIFI_INTERFACE${NC}"
    iwctl station $WIFI_INTERFACE scan
    
    echo -e "\n${CYAN}:: Available Networks ::${NC}"
    iwctl station $WIFI_INTERFACE get-networks
    echo ""

    while true; do
        echo -e "${ICON_ASK} WiFi Authentication Required"
        ask_input "WIFI_SSID" "SSID Name"
        
        echo -ne "${YELLOW}${BOLD} ➜ ${NC}${WHITE}Password${NC}: "
        read -s WIFI_PASS
        echo ""
        
        echo -e "${ICON_INF} Authenticating with ${BOLD}$WIFI_SSID${NC}..."
        iwctl --passphrase "$WIFI_PASS" station $WIFI_INTERFACE connect "$WIFI_SSID"
        
        echo -e "${ICON_INF} Verifying Handshake (8s timeout)..."
        sleep 8
        
        if ping -c 1 google.com &> /dev/null; then
            echo -e "${ICON_OK} ${GREEN}Connection Established Successfully.${NC}"
            timedatectl set-ntp true
            break
        else
            echo -e "${ICON_ERR} ${RED}Connection Failed.${NC}"
            echo -e "${DIM}Retrying authentication sequence...${NC}\n"
        fi
    done
fi
sleep 1

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
    CLEAN_NAME=${DRIVE_INPUT#/dev/}
    TARGET_DISK="/dev/$CLEAN_NAME"
    
    if lsblk -d "$TARGET_DISK" &>/dev/null; then
        echo -e "${ICON_OK} Target Locked: ${BOLD}$TARGET_DISK${NC}"
        break
    else
        echo -e "${ICON_ERR} Device not found."
    fi
done

# 4.2 Hardware Analysis
echo -e "\n${ICON_INF} Running Hardware Analysis..."
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$(($TOTAL_RAM_KB / 1024 / 1024))

echo -e "   [RAM]  Detected ${BOLD}${TOTAL_RAM_GB}GB${NC} System Memory."
if [ $TOTAL_RAM_GB -ge 8 ]; then
    echo -e "          -> Strategy: Standard Swapfile (4GB)."
else
    echo -e "          -> Strategy: ${YELLOW}Low Memory.${NC} Swapfile is critical."
fi

# 4.3 Strategy Selection
while true; do
    echo -e "\n${ICON_INF} Select Partitioning Strategy"
    echo -e "  ${CYAN} 1)${NC} Use Free Space (Dual Boot Safe)"
    echo -e "  ${CYAN} 2)${NC} Wipe Entire Disk (Clean Install)"
    echo -e "  ${CYAN} 3)${NC} Manual Mode (Advanced)"
    echo ""

    ask_input "STRATEGY_OPT" "Select Strategy Number"

    # Reset vars
    ROOT_PART=""
    EFI_PART=""
    FORMAT_EFI="no"

    case $STRATEGY_OPT in
        1)
            # --- USE FREE SPACE ---
            echo -e "${ICON_INF} Scanning for unallocated space..."
            # Execute logic from v1.6 (Robust Mode)
            sgdisk -n 0:0:0 -t 0:8304 -c 0:"Arch Root" $TARGET_DISK &>/dev/null

            echo -e "${ICON_OK} Syncing Disk Map..."
            partprobe $TARGET_DISK && sync && sleep 2
            
            ROOT_PART=$(lsblk -n -o PATH,PARTLABEL $TARGET_DISK | grep "Arch Root" | tail -n1 | awk '{print $1}')
            
            if [[ -z "$ROOT_PART" ]]; then
                 echo -e "${ICON_WRN} Auto-detect needs confirmation."
                 echo -e "${ICON_INF} Current Partitions:"
                 lsblk $TARGET_DISK -o NAME,SIZE,TYPE,LABEL
                 ask_input "ROOT_INPUT" "Identify the new Partition (e.g. nvme0n1p3)"
                 ROOT_PART="/dev/${ROOT_INPUT#/dev/}"
            else
                 echo -e "${ICON_OK} Auto-Detected New Partition: ${BOLD}$ROOT_PART${NC}"
            fi
            
            AUTO_EFI=$(fdisk -l $TARGET_DISK | grep 'EFI System' | awk '{print $1}' | head -n 1)
            if [[ -n "$AUTO_EFI" ]]; then
                EFI_PART=$AUTO_EFI
                FORMAT_EFI="no"
                echo -e "${ICON_OK} Detected Windows Boot Manager at ${BOLD}$EFI_PART${NC}"
                break
            else
                echo -e "${ICON_ERR} No EFI Partition found. System requires EFI."
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
            sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System" $TARGET_DISK &>/dev/null
            sgdisk -n 2:0:0     -t 2:8304 -c 2:"Arch Root"  $TARGET_DISK &>/dev/null
            partprobe $TARGET_DISK && sync && sleep 3
            
            if [[ "$TARGET_DISK" == *"nvme"* ]]; then
                EFI_PART="${TARGET_DISK}p1"; ROOT_PART="${TARGET_DISK}p2"
            else
                EFI_PART="${TARGET_DISK}1"; ROOT_PART="${TARGET_DISK}2"
            fi
            FORMAT_EFI="yes"
            break
            ;;
            
        3)
            # --- MANUAL ---
            echo -e "${ICON_INF} Launching cfdisk..."
            read -p "Press Enter to continue..."
            cfdisk $TARGET_DISK
            partprobe $TARGET_DISK && sync && sleep 3
            
            echo -e "\n${CYAN}:: Partition Map ::${NC}"
            lsblk $TARGET_DISK -o NAME,SIZE,TYPE,FSTYPE,LABEL
            
            ask_input "E_IN" "Select EFI Partition"
            EFI_PART="/dev/${E_IN#/dev/}"
            ask_input "FORMAT_EFI" "Format EFI? (yes/no)"
            
            ask_input "R_IN" "Select Root Partition"
            ROOT_PART="/dev/${R_IN#/dev/}"
            break
            ;;
        *)
            echo "Invalid Option." ;;
    esac
done

# 4.5 Safety Verification
if [ ! -b "$ROOT_PART" ] || [ ! -b "$EFI_PART" ]; then
    echo -e "${ICON_ERR} Partition check failed. Defined partitions do not exist."
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
# SECTION 5: INSTALLATION PROCESS (CLASSIC V1.5 ENGINE)
# ==============================================================================
start_step "5" "CORE INSTALLATION"

# 5.1 Optimization
echo -e "${ICON_INF} Optimizing Pacman (Parallel Downloads)..."
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

# 5.5 Base Install (RESTORED V1.5 LOGIC - NO REFLECTOR, NO KEYRING)
echo -e "${ICON_INF} Downloading and Installing Base System..."
echo -e "${DIM} (Output visible to track progress)${NC}"

# Using the EXACT simple command from v1.5
# But WITHOUT '&>/dev/null' so you can see it working
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware base-devel \
    $UCODE mesa pipewire pipewire-alsa pipewire-pulse wireplumber \
    networkmanager bluez bluez-utils power-profiles-daemon \
    git nano ntfs-3g dosfstools mtools

echo -e "\n${ICON_OK} Core packages installed."
echo -e "${ICON_INF} Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# ==============================================================================
# SECTION 6: SYSTEM CONFIGURATION
# ==============================================================================
start_step "6" "USER & SYSTEM CONFIGURATION"

ask_input "MY_USER" "Enter Desired Username"
while true; do
    echo -ne "${YELLOW}${BOLD} ➜ ${NC}${WHITE}Password${NC}: "
    read -s P1; echo
    echo -ne "${YELLOW}${BOLD} ➜ ${NC}${WHITE}Confirm Password${NC}: "
    read -s P2; echo
    [[ "$P1" == "$P2" && -n "$P1" ]] && MY_PASS="$P1" && break
    echo -e "${ICON_ERR} Passwords do not match."
done

export TIMEZONE LOCALE KEYMAP MY_HOSTNAME MY_USER MY_PASS

echo -e "${ICON_INF} Configuring System Internals (Chroot)..."
arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo "$LOCALE UTF-8" > /etc/locale.gen
locale-gen > /dev/null
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$MY_HOSTNAME" > /etc/hostname

echo "root:$MY_PASS" | chpasswd
useradd -m -G wheel,storage,power,video -s /bin/bash $MY_USER
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

# ==============================================================================
# FINALIZATION
# ==============================================================================
hard_clear
print_banner
echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}   INSTALLATION SUCCESSFUL v2.0.0 ${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}"
echo -e ""
echo -e " 1. Remove installation media."
echo -e " 2. Type ${BOLD}reboot${NC} to start your new system."
echo -e " 3. Login as: ${BOLD}$MY_USER${NC}"
echo -e ""
echo -e "${DIM} Welcome to the Arch Linux family.${NC}"
echo -e ""

#!/bin/bash

# ==============================================================================
#  ARCH LINUX UNIVERSAL INSTALLER v1.1.0
#  Installing arch the easy way.
# ==============================================================================

# --- [0] SAFETY PRE-FLIGHT ----------------------------------------------------
# Strict Mode: Error on unset variables, fail on pipe errors
set -uo pipefail

# Global State for Trap
DISK_MODIFIED=0

# Trap Function: Restores cursor and warns if disk was left dirty
cleanup() {
    tput cnorm
    if [[ "$DISK_MODIFIED" -eq 1 ]]; then
        echo -e "\n${YELLOW} WARN ${NC} Script stopped after disk modification."
        echo -e "${DIM} The system may be in a partial or unbootable state.${NC}"
    fi
}
trap cleanup EXIT

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
    echo "  >> UNIVERSAL INSTALLER SYSTEM v2.4.0"
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

# --- [3] ANIMATION UTILITIES --------------------------------------------------
function show_progress_bar {
    local pid=$1
    local delay=0.1
    local width=30
    local i=0
    local direction=1
    
    tput civis
    echo -ne "\n  ${BOLD}Installing:${NC} ["
    
    while ps -p "$pid" > /dev/null; do
        local bar=""
        for ((j=0; j<width; j++)); do
            if [ $j -eq $i ]; then bar+="<=>"; else bar+=" "; fi
        done
        printf "\r  ${BOLD}Installing:${NC} [${CYAN}%-${width}s${NC}]" "${bar:0:$width}"
        
        i=$((i + direction))
        if [ $i -ge $((width - 3)) ] || [ $i -le 0 ]; then direction=$((direction * -1)); fi
        sleep $delay
    done
    
    local full_bar=$(printf '=%0.s' $(seq 1 $width))
    printf "\r  ${BOLD}Installing:${NC} [${CYAN}$full_bar${NC}] Done\n"
    sleep 1
    tput cnorm
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
    if [[ "$CITY_INPUT" =~ ^[0-9]+$ ]] && [ "$CITY_INPUT" -ge 1 ] && [ "$CITY_INPUT" -le "${#short_cities[@]}" ]; then
        CITY="${short_cities[$((CITY_INPUT-1))]}"
    else
        CITY="$CITY_INPUT"
    fi
    
    if [ -f "/usr/share/zoneinfo/$REGION/$CITY" ]; then
        TIMEZONE="$REGION/$CITY"
        echo -e "${ICON_OK} Timezone set to: ${BOLD}$TIMEZONE${NC}"
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

if ping -c 1 google.com &> /dev/null || true; then
    if ping -c 1 google.com &> /dev/null; then
        echo -e "${ICON_OK} Internet Connection: ${GREEN}Active${NC}"
    else
        echo -e "${ICON_ERR} Internet Connection: ${RED}Offline${NC}"
        echo -e "${DIM}Initializing Wireless Interface...${NC}"
        
        WIFI_INTERFACE=$(iw dev | awk '$1=="Interface"{print $2; exit}')
        
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
                
                echo -e "${ICON_INF} Authenticating with ${BOLD}$WIFI_SSID${NC}..."
                iwctl --passphrase "$WIFI_PASS" station "$WIFI_INTERFACE" connect "$WIFI_SSID"
                
                echo -e "${ICON_INF} Verifying Handshake (8s timeout)..."
                sleep 8
                
                if ping -c 1 google.com &> /dev/null; then
                    echo -e "${ICON_OK} ${GREEN}Connection Established Successfully.${NC}"
                    timedatectl set-ntp true
                    break
                else
                    echo -e "${ICON_ERR} ${RED}Connection Failed.${NC}"
                fi
            done
        fi
    fi
fi
sleep 1

# ==============================================================================
# SECTION 4: STORAGE CONFIGURATION
# ==============================================================================
start_step "4" "STORAGE ARCHITECTURE"

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

echo -e "\n${ICON_INF} Running Hardware Analysis..."
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$(($TOTAL_RAM_KB / 1024 / 1024))

echo -e "   [RAM]  Detected ${BOLD}${TOTAL_RAM_GB}GB${NC} System Memory."

if [ $TOTAL_RAM_GB -ge 8 ]; then
    echo -e "          -> Strategy: Standard Swapfile (4GB)."
    SWAP_SIZE=4
else
    echo -e "          -> Strategy: ${YELLOW}Low Memory.${NC} Swapfile increased to 8GB."
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
            echo -e "${ICON_INF} Scanning for unallocated space..."
            sgdisk -n 0:0:0 -t 0:8304 -c 0:"Arch Root" "$TARGET_DISK" &>/dev/null
            partprobe "$TARGET_DISK" && sync && sleep 2
            
            ROOT_PART=$(lsblk -n -o PATH,PARTLABEL "$TARGET_DISK" | grep "Arch Root" | tail -n1 | awk '{print $1}')
            
            if [[ -z "$ROOT_PART" ]]; then
                 echo -e "${ICON_WRN} Auto-detect needs confirmation."
                 lsblk "$TARGET_DISK" -o NAME,SIZE,TYPE,LABEL
                 ask_input "ROOT_INPUT" "Identify the new Partition (e.g. nvme0n1p3)"
                 ROOT_PART="/dev/${ROOT_INPUT#/dev/}"
            else
                 echo -e "${ICON_OK} Auto-Detected New Partition: ${BOLD}$ROOT_PART${NC}"
            fi
            
            AUTO_EFI=$(fdisk -l "$TARGET_DISK" | grep 'EFI System' | awk '{print $1}' | head -n 1)
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
            echo -e "\n${RED}${BOLD}CRITICAL WARNING: THIS WILL DESTROY ALL DATA ON $TARGET_DISK${NC}"
            ask_input "CONFIRM" "Type 'DESTROY' to confirm"
            [[ "$CONFIRM" != "DESTROY" ]] && echo "Aborted." && exit 1
            
            sgdisk -Z "$TARGET_DISK" &>/dev/null
            sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System" "$TARGET_DISK" &>/dev/null
            sgdisk -n 2:0:0     -t 2:8304 -c 2:"Arch Root"  "$TARGET_DISK" &>/dev/null
            partprobe "$TARGET_DISK" && sync && sleep 3
            
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
            cfdisk "$TARGET_DISK"
            partprobe "$TARGET_DISK" && sync && sleep 3
            
            echo -e "\n${CYAN}:: Partition Map ::${NC}"
            lsblk "$TARGET_DISK" -o NAME,SIZE,TYPE,FSTYPE,LABEL
            
            ask_input "E_IN" "Select EFI Partition"
            EFI_PART="/dev/${E_IN#/dev/}"
            ask_input "FORMAT_EFI" "Format EFI? (yes/no)"
            
            if [[ "$FORMAT_EFI" == "yes" ]]; then
                echo -e "${YELLOW}WARNING: Formatting EFI will delete all other bootloaders (Windows/Fedora)!${NC}"
                ask_input "EFI_CONFIRM" "Are you sure?"
                [[ "$EFI_CONFIRM" != "yes" ]] && FORMAT_EFI="no"
            fi
            
            ask_input "R_IN" "Select Root Partition"
            ROOT_PART="/dev/${R_IN#/dev/}"
            break
            ;;
        *)
            echo "Invalid Option." ;;
    esac
done

if [ ! -b "$ROOT_PART" ] || [ ! -b "$EFI_PART" ]; then
    echo -e "${ICON_ERR} Partition check failed. Defined partitions do not exist."
    exit 1
fi

echo -e "\n${GREEN}=== CONFIGURATION SUMMARY ===${NC}"
echo -e " Target Disk : ${WHITE}$TARGET_DISK${NC}"
echo -e " EFI Boot    : ${WHITE}$EFI_PART${NC} (Format: $FORMAT_EFI)"
echo -e " System Root : ${WHITE}$ROOT_PART${NC} (Format: YES)"
echo -e " Swap Size   : ${WHITE}${SWAP_SIZE}GB${NC}"
echo -e "${GREEN}=============================${NC}"

ask_input "CONFIRM" "Type 'yes' to proceed with installation"
[[ "$CONFIRM" != "yes" ]] && exit 1

# ==============================================================================
# SECTION 5: INSTALLATION PROCESS
# ==============================================================================
start_step "5" "CORE INSTALLATION"

# PRO FIX: "Pulse Check" to prevent hanging
echo -e "${ICON_INF} Verifying connection before download..."
if ! ping -c 1 google.com &>/dev/null; then
    echo -e "${ICON_ERR} Connection lost. Cannot proceed with download."
    exit 1
fi

# PRO FIX: Mark disk as modified for trap handler
DISK_MODIFIED=1

if command -v reflector &>/dev/null; then
    echo -e "${ICON_INF} Optimizing Mirrors (Reflector)..."
    reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist &>/dev/null || true
fi

echo -e "${ICON_INF} Optimizing Pacman (Parallel Downloads)..."
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

echo -e "${ICON_INF} Formatting Filesystems..."
mkfs.ext4 -F "$ROOT_PART" &>/dev/null
if [[ "$FORMAT_EFI" == "yes" ]]; then
    mkfs.vfat -F32 "$EFI_PART" &>/dev/null
fi

echo -e "${ICON_INF} Mounting Partitions..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot

echo -e "${ICON_INF} Detecting CPU..."
if grep -q "AuthenticAMD" /proc/cpuinfo; then
    UCODE="amd-ucode"
    echo -e "${ICON_OK} AMD CPU Detected."
else
    UCODE="intel-ucode"
    echo -e "${ICON_OK} Intel CPU Detected."
fi

echo -e "${ICON_INF} Installing Base System..."
echo -e "${DIM} (Logs available at /tmp/arch-install.log)${NC}"

pacstrap /mnt base linux linux-headers linux-firmware base-devel \
    "$UCODE" mesa pipewire pipewire-alsa pipewire-pulse wireplumber \
    networkmanager bluez bluez-utils power-profiles-daemon \
    git nano ntfs-3g dosfstools mtools &> /tmp/arch-install.log &

INSTALL_PID=$!
show_progress_bar $INSTALL_PID

wait $INSTALL_PID
if [ $? -eq 0 ]; then
    echo -e "${ICON_OK} Core packages installed."
else
    echo -e "\n${ICON_ERR} Installation Failed. Check /tmp/arch-install.log"
    exit 1
fi

echo -e "${ICON_INF} Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# ==============================================================================
# SECTION 6: SYSTEM CONFIGURATION
# ==============================================================================
start_step "6" "USER & SYSTEM CONFIGURATION"

while true; do
    ask_input "MY_USER" "Enter Desired Username"
    if [[ "$MY_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        break
    else
        echo -e "${ICON_ERR} Invalid format. Use lowercase letters, numbers, _ or - only."
    fi
done

while true; do
    echo -ne "${YELLOW}${BOLD} ➜ ${NC}${WHITE}Password${NC}: "
    read -s P1; echo
    echo -ne "${YELLOW}${BOLD} ➜ ${NC}${WHITE}Confirm Password${NC}: "
    read -s P2; echo
    [[ "$P1" == "$P2" && -n "$P1" ]] && MY_PASS="$P1" && break
    echo -e "${ICON_ERR} Passwords do not match."
done
echo ""

export SWAP_SIZE

echo -e "${ICON_INF} Configuring System Internals..."

arch-chroot /mnt /bin/bash <<EOF
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc &>/dev/null

sed -i "s/^#$LOCALE/$LOCALE/" /etc/locale.gen
locale-gen &>/dev/null
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$MY_HOSTNAME" > /etc/hostname

echo "root:$MY_PASS" | chpasswd
useradd -m -G wheel,storage,power,video -s /bin/bash "$MY_USER"
echo "$MY_USER:$MY_PASS" | chpasswd

echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/00_arch_installer
chmod 440 /etc/sudoers.d/00_arch_installer

pacman -S --noconfirm grub efibootmgr os-prober &>/dev/null
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch &>/dev/null
grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null

systemctl enable NetworkManager &>/dev/null
systemctl enable power-profiles-daemon &>/dev/null
systemctl enable bluetooth &>/dev/null
systemctl enable fstrim.timer &>/dev/null

sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j\$(nproc)\"/" /etc/makepkg.conf

dd if=/dev/zero of=/swapfile bs=1G count=$SWAP_SIZE status=none
chmod 600 /swapfile
mkswap /swapfile &>/dev/null
swapon /swapfile &>/dev/null
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

echo "set tabsize 4" > "/home/$MY_USER/.nanorc"
echo "set tabstospaces" >> "/home/$MY_USER/.nanorc"
chown "$MY_USER:$MY_USER" "/home/$MY_USER/.nanorc"
EOF

unset MY_PASS P1 P2
DISK_MODIFIED=0

# ==============================================================================
# FINALIZATION
# ==============================================================================
hard_clear
print_banner
echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}${BOLD}   INSTALLATION SUCCESSFUL v2.4.0 ${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}"
echo -e ""
echo -e " 1. Remove installation media."
echo -e " 2. Type ${BOLD}reboot${NC} to start your new system."
echo -e " 3. Login as: ${BOLD}$MY_USER${NC}"
echo -e ""
echo -e "${DIM} Welcome to the Arch Linux family.${NC}"
echo -e ""

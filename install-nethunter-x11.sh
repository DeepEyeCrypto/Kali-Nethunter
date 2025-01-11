#!/data/data/com.termux/files/usr/bin/bash -e

# Variables
VERSION=2024091801
BASE_URL=https://kali.download/nethunter-images/current/rootfs
USERNAME=kali
SYS_ARCH=arm64
CHROOT=chroot/kali-${SYS_ARCH}
IMAGE_NAME=kali-nethunter-rootfs-full-${SYS_ARCH}.tar.xz
SHA_NAME=${IMAGE_NAME}.sha512sum

# Add colors
red='\033[1;31m'
green='\033[1;32m'
blue='\033[1;34m'
reset='\033[0m'

# Banner
function print_banner() {
    clear
    echo -e "${blue}##################################################"
    echo -e "##                                              ##"
    echo -e "##  Kali NetHunter Desktop DeeEyeCrypto...      ##"
    echo -e "##                                              ##"
    echo -e "##################################################${reset}"
}

# Update and install dependencies
function check_dependencies() {
    echo -e "${blue}[*] Updating Termux packages and installing dependencies...${reset}"
    pkg update -y
    pkg upgrade -y
    pkg install x11-repo -y
    pkg install termux-x11-nightly -y
    pkg install pulseaudio -y
    pkg install wget -y
    pkg install xfce4 -y
    pkg install tur-repo -y
    pkg install firefox -y
    pkg install proot-distro -y
    pkg install git -y
    termux-setup-storage
}

# Download rootfs
function download_rootfs() {
    echo -e "${blue}[*] Downloading rootfs...${reset}"
    wget --continue "${BASE_URL}/${IMAGE_NAME}"
    wget --continue "${BASE_URL}/${SHA_NAME}"
}

# Verify rootfs integrity
function verify_rootfs() {
    echo -e "${blue}[*] Verifying rootfs integrity...${reset}"
    sha512sum -c "${SHA_NAME}" || {
        echo -e "${red}[!] Rootfs is corrupted. Exiting.${reset}"
        exit 1
    }
}

# Extract rootfs
function extract_rootfs() {
    echo -e "${blue}[*] Extracting rootfs...${reset}"
    mkdir -p ${CHROOT}
    proot --link2symlink tar -xf "${IMAGE_NAME}" -C ${CHROOT}
}

# Configure X11 and XFCE4
function setup_x11_environment() {
    echo -e "${blue}[*] Setting up X11 and XFCE4 environment...${reset}"
    cat > ${CHROOT}/root/.xinitrc <<- EOF
#!/bin/sh
xrdb $HOME/.Xresources
xsetroot -solid black
startxfce4 &
EOF
    chmod +x ${CHROOT}/root/.xinitrc
}

# Create NetHunter launcher
function create_launcher() {
    NH_LAUNCHER=${PREFIX}/bin/nethunter
    cat > "$NH_LAUNCHER" <<- EOF
#!/data/data/com.termux/files/usr/bin/bash -e
unset LD_PRELOAD
user="$USERNAME"
home="/home/\$user"
cmdline="proot --link2symlink -0 -r $CHROOT -b /dev -b /proc -b /sdcard -b $CHROOT\$home:/dev/shm -w \$home \\
        /usr/bin/env -i HOME=\$home PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin TERM=\$TERM LANG=C.UTF-8 /bin/bash"

if [ "\$#" == "0" ]; then
    exec \$cmdline
else
    \$cmdline -c "\$@"
fi
EOF
    chmod +x "$NH_LAUNCHER"
}

# Create X11 desktop launcher
function create_desktop_launcher() {
    DESKTOP_LAUNCHER=${PREFIX}/bin/startdesktop
    cat > "$DESKTOP_LAUNCHER" <<- EOF
#!/data/data/com.termux/files/usr/bin/bash -e
unset LD_PRELOAD
export DISPLAY=:0
export PULSE_SERVER=unix:/data/data/com.termux/files/usr/tmp/pulse-server
proot --link2symlink -0 -r $CHROOT -b /dev -b /proc -b /sdcard -b $CHROOT/home/kali:/dev/shm -w /root \\
        /usr/bin/env -i HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin TERM=\$TERM LANG=C.UTF-8 startxfce4
EOF
    chmod +x "$DESKTOP_LAUNCHER"
}

# Cleanup downloaded files
function cleanup() {
    echo -e "${blue}[*] Cleaning up downloaded files...${reset}"
    rm -f "${IMAGE_NAME}" "${SHA_NAME}"
}

# Main Function
print_banner
check_dependencies
download_rootfs
verify_rootfs
extract_rootfs
setup_x11_environment
create_launcher
create_desktop_launcher
cleanup

# Final Instructions
print_banner
echo -e "${green}[=] Kali NetHunter Desktop for Termux-X11 installed successfully.${reset}"
echo -e "${green}[+] Use 'nethunter' to access the CLI environment.${reset}"
echo -e "${green}[+] Use 'startdesktop' to directly launch the XFCE4 desktop in Termux-X11.${reset}"

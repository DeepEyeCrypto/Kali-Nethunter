#!/data/data/com.termux/files/usr/bin/bash -e

VERSION=2024091801
BASE_URL=https://kali.download/nethunter-images/current/rootfs
USERNAME=kali

# Function for unsupported architecture
function unsupported_arch() {
    echo "[*] Unsupported Architecture" && exit 1
}

# Function for asking user input
function ask() {
    while true; do
        prompt="${2:-y/n}"
        read -p "$1 [$prompt]: " REPLY
        REPLY=${REPLY:-${2}}
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
    done
}

# Function to check device architecture
function get_arch() {
    case $(getprop ro.product.cpu.abi) in
        arm64-v8a) SYS_ARCH=arm64 ;;
        armeabi|armeabi-v7a) SYS_ARCH=armhf ;;
        *) unsupported_arch ;;
    esac
}

# Function to install Termux-X11 and dependencies
function install_x11() {
    echo "[*] Installing Termux-X11 dependencies..."
    pkg update -y
    pkg install -y x11-repo proot-distro termux-x11 vnc-server
}

# Function to configure Termux-X11 environment
function configure_x11() {
    echo "[*] Configuring Termux-X11 desktop..."
    echo "export DISPLAY=:1" >> ~/.bashrc
    mkdir -p ~/.vnc
    echo -e "password\npassword\nn" | vncpasswd
}

# Function to download and install Kali rootfs
function setup_kali() {
    echo "[*] Setting up Kali NetHunter rootfs..."
    IMAGE_NAME="kali-nethunter-rootfs-full-${SYS_ARCH}.tar.xz"
    wget --continue "${BASE_URL}/${IMAGE_NAME}" || { echo "Failed to download image."; exit 1; }
    mkdir -p kali-rootfs && tar -xf "$IMAGE_NAME" -C kali-rootfs
    echo "[+] Rootfs extracted to kali-rootfs/"
}

# Function to clean up after installation
function cleanup() {
    echo "[*] Cleaning up installation files..."
    rm -f "${IMAGE_NAME}" || echo "No image file to remove."
    rm -rf kali-rootfs || echo "No rootfs directory to remove."
}

# Main installation sequence
function main() {
    echo "[*] Starting Kali NetHunter installation on Termux-X11..."
    get_arch
    install_x11
    setup_kali
    configure_x11
    cleanup
    echo "[+] Kali NetHunter with Termux-X11 installed successfully!"
    echo "[+] To start the desktop, use: vncserver -localhost no :1"
}

main

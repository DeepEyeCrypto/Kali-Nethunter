#!/data/data/com.termux/files/usr/bin/bash -e

VERSION=20250112
USERNAME=termux
TERMUX_HOME="$HOME"
INSTALL_DIR="$TERMUX_HOME/termux-x11"
LOG_FILE="$HOME/termux-x11-install.log"

# Colors for messages
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
RESET='\033[0m'

function log() {
    echo -e "${BLUE}$*${RESET}" | tee -a "$LOG_FILE"
}

function warn() {
    echo -e "${YELLOW}$*${RESET}" | tee -a "$LOG_FILE"
}

function error() {
    echo -e "${RED}$*${RESET}" | tee -a "$LOG_FILE" >&2
}

function success() {
    echo -e "${GREEN}$*${RESET}" | tee -a "$LOG_FILE"
}

function unsupported_arch() {
    error "[*] Unsupported Architecture. Exiting."
    exit 1
}

function check_architecture() {
    log "[*] Checking device architecture..."
    case $(getprop ro.product.cpu.abi) in
        arm64-v8a)
            SYS_ARCH=arm64
            ;;
        armeabi|armeabi-v7a)
            SYS_ARCH=armhf
            ;;
        *)
            unsupported_arch
            ;;
    esac
}

function install_dependencies() {
    log "[*] Installing dependencies..."
    apt update && apt upgrade -y
    apt install -y x11-repo xwayland pulseaudio proot wget tar xfce4 xfce4-terminal \
        htop neofetch file-roller pcmanfm || {
        error "[!] Failed to install dependencies."
        exit 1
    }
}

function setup_termux_x11() {
    log "[*] Setting up Termux-X11..."
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
    fi

    wget -O "$INSTALL_DIR/termux-x11.apk" https://github.com/termux/termux-x11/releases/latest/download/termux-x11.apk
    if [ -f "$INSTALL_DIR/termux-x11.apk" ]; then
        log "[*] APK downloaded. Attempting to install via ADB..."
        adb install "$INSTALL_DIR/termux-x11.apk" || {
            warn "[!] ADB installation failed. Please install manually:"
            warn "adb install $INSTALL_DIR/termux-x11.apk"
        }
    else
        error "[!] Failed to download Termux-X11 APK."
        exit 1
    fi
}

function configure_x11() {
    log "[*] Configuring X11 environment..."
    export PULSE_SERVER=127.0.0.1
    pulseaudio --start

    # Add environment variables to .bashrc
    if ! grep -q "export DISPLAY=:0" ~/.bashrc; then
        echo "export DISPLAY=:0" >> ~/.bashrc
    fi
    if ! grep -q "export PULSE_SERVER=127.0.0.1" ~/.bashrc; then
        echo "export PULSE_SERVER=127.0.0.1" >> ~/.bashrc
    fi
    source ~/.bashrc
}

function setup_desktop_environment() {
    log "[*] Setting up Desktop Environment..."
    mkdir -p ~/.vnc

    read -p "Enter desired VNC port (default: 5901): " VNC_PORT
    VNC_PORT=${VNC_PORT:-5901}

    read -p "Enter desired resolution (e.g., 1280x720, default: 1920x1080): " RESOLUTION
    RESOLUTION=${RESOLUTION:-1920x1080}

    log "[*] Choose your desktop environment:"
    log "1. XFCE (default)"
    log "2. LXDE (lightweight)"
    read -p "Enter your choice (1 or 2): " DE_CHOICE
    DE_CHOICE=${DE_CHOICE:-1}

    if [ "$DE_CHOICE" -eq 2 ]; then
        apt install -y lxde
        DESKTOP_CMD="startlxde"
    else
        DESKTOP_CMD="startxfce4"
    fi

    echo "#!/bin/sh" > ~/.vnc/xstartup
    echo "$DESKTOP_CMD" >> ~/.vnc/xstartup
    chmod +x ~/.vnc/xstartup

    LAUNCHER="$INSTALL_DIR/start-x11.sh"
    cat > "$LAUNCHER" <<- EOF
#!/data/data/com.termux/files/usr/bin/bash
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
pulseaudio --start
termux-x11 --vnc-port=$VNC_PORT --resolution=$RESOLUTION &
sleep 3
$DESKTOP_CMD
EOF
    chmod +x "$LAUNCHER"
    log "[*] To start Termux-X11 and the desktop, run: $LAUNCHER"
}

function enable_auto_start() {
    read -p "Enable auto-start for Termux-X11? (y/n, default: y): " AUTO_START
    AUTO_START=${AUTO_START:-y}

    if [[ "$AUTO_START" =~ ^[Yy]$ ]]; then
        log "[*] Enabling auto-start..."
        AUTO_START_SCRIPT="$PREFIX/etc/profile.d/start-x11.sh"
        cat > "$AUTO_START_SCRIPT" <<- EOF
#!/data/data/com.termux/files/usr/bin/bash
if [ ! -z "\$TERMUX_X11_AUTO_START" ]; then
    $INSTALL_DIR/start-x11.sh
fi
EOF
        chmod +x "$AUTO_START_SCRIPT"
        echo "export TERMUX_X11_AUTO_START=1" >> ~/.bashrc
        source ~/.bashrc
    else
        log "[*] Auto-start disabled."
    fi
}

function test_environment() {
    log "[*] Testing Termux-X11 setup..."
    if termux-x11 --help >/dev/null 2>&1; then
        success "[+] Termux-X11 is installed correctly."
    else
        error "[!] Termux-X11 installation failed."
    fi
    if pulseaudio --check >/dev/null 2>&1; then
        success "[+] PulseAudio is running."
    else
        error "[!] PulseAudio setup failed."
    fi
}

function cleanup() {
    log "[*] Cleaning up..."
    rm -f "$INSTALL_DIR/termux-x11.apk"
}

function print_banner() {
    clear
    log "##################################################"
    log "#       Termux-X11 Desktop Automation Setup      #"
    log "##################################################"
}

function main() {
    print_banner
    check_architecture
    install_dependencies
    setup_termux_x11
    configure_x11
    setup_desktop_environment
    enable_auto_start
    test_environment
    cleanup
    success "[*] Termux-X11 setup completed. Restart Termux to apply changes."
}

main

#!/data/data/com.termux/files/usr/bin/bash -e

VERSION=2024091801
BASE_URL=https://kali.download/nethunter-images/current/rootfs
USERNAME=kali
LOG_FILE="$HOME/nethunter-installation.log"

# Add some colours
red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
blue='\033[1;34m'
light_cyan='\033[1;96m'
reset='\033[0m'

# Logging function
function log() {
    local msg="$1"
    local level="${2:-INFO}"
    printf "[$level] $msg\n" | tee -a "$LOG_FILE"
}

function unsupported_arch() {
    log "[*] Unsupported Architecture" "ERROR"
    exit 1
}

function ask() {
    while true; do
        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        printf "${light_cyan}\n[?] "
        read -p "$1 [$prompt] " REPLY
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi

        printf "${reset}"

        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
    done
}

function get_arch() {
    log "Checking device architecture..."
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
    log "Device architecture: $SYS_ARCH"
}

function prepare_fs() {
    if [ -d ${CHROOT} ]; then
        if ask "Existing rootfs directory found. Delete and create a new one?" "N"; then
            rm -rf ${CHROOT}
            log "Deleted existing rootfs directory."
        else
            KEEP_CHROOT=1
            log "Using existing rootfs directory."
        fi
    fi
}

function check_dependencies() {
    log "Checking package dependencies..."
    apt-get update -y &>> "$LOG_FILE" || apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade -y &>> "$LOG_FILE"
    for i in proot tar wget; do
        if [ -e "$PREFIX"/bin/$i ]; then
            log "$i is installed."
        else
            log "Installing $i..."
            apt install -y $i &>> "$LOG_FILE" || {
                log "Failed to install $i." "ERROR"
                exit 1
            }
        fi
    done
    log "All dependencies are satisfied."
}

function install_x11_desktop() {
    log "Installing Termux-X11..."
    apt install -y x11-repo &>> "$LOG_FILE" || {
        log "Failed to install x11-repo." "ERROR"
        exit 1
    }
    apt install -y termux-x11 &>> "$LOG_FILE" || {
        log "Failed to install Termux-X11." "ERROR"
        exit 1
    }

    printf "\n${blue}[?] Choose your preferred desktop environment:${reset}\n"
    printf "[1] XFCE\n[2] LXDE\n[3] GNOME\n"
    read -p "Enter your choice (1/2/3): " desktop_choice

    case $desktop_choice in
        1)
            apt install -y xfce4 firefox &>> "$LOG_FILE" || {
                log "Failed to install XFCE desktop environment." "ERROR"
                exit 1
            }
            DESKTOP_ENV="XFCE"
            ;;
        2)
            apt install -y lxde-core lxterminal firefox &>> "$LOG_FILE" || {
                log "Failed to install LXDE desktop environment." "ERROR"
                exit 1
            }
            DESKTOP_ENV="LXDE"
            ;;
        3)
            apt install -y gnome-session gnome-terminal firefox &>> "$LOG_FILE" || {
                log "Failed to install GNOME desktop environment." "ERROR"
                exit 1
            }
            DESKTOP_ENV="GNOME"
            ;;
        *)
            log "Invalid choice. Defaulting to XFCE."
            apt install -y xfce4 firefox &>> "$LOG_FILE" || {
                log "Failed to install XFCE desktop environment." "ERROR"
                exit 1
            }
            DESKTOP_ENV="XFCE"
            ;;
    esac
    log "$DESKTOP_ENV Desktop installed successfully."
}

function configure_x11_launcher() {
    log "Configuring desktop launcher..."
    cat > ${PREFIX}/bin/start-desktop <<- EOF
#!/data/data/com.termux/files/usr/bin/bash
termux-x11 :1 &
sleep 5
export DISPLAY=:1
start${DESKTOP_ENV,,}4
EOF
    chmod +x ${PREFIX}/bin/start-desktop
    log "Desktop launcher configured for $DESKTOP_ENV. Run 'start-desktop' to launch."
}

function post_install_cleanup() {
    log "Cleaning up installation files..."
    rm -rf ${CHROOT} &>> "$LOG_FILE"
    log "Installation files cleaned up."
}

# Main Execution
log "Starting NetHunter installation."
get_arch
prepare_fs
check_dependencies
install_x11_desktop
configure_x11_launcher
post_install_cleanup
log "NetHunter installation completed successfully."

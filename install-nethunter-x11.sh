#!/data/data/com.termux/files/usr/bin/bash -e

VERSION=2024091801
BASE_URL=https://kali.download/nethunter-images/current/rootfs
USERNAME=kali

# Add colors
red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
blue='\033[1;34m'
reset='\033[0m'

function unsupported_arch() {
    printf "${red}[!] Unsupported Architecture. Exiting.${reset}\n"
    exit 1
}

function get_arch() {
    printf "${blue}[+] Detecting device architecture...${reset}\n"
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

function set_strings() {
    printf "${blue}[+] Setting download image parameters...${reset}\n"
    case ${SYS_ARCH} in
        arm64)
            wimg="full"
            ;;
        armhf)
            wimg="nano"
            ;;
    esac
    CHROOT=chroot/kali-${SYS_ARCH}
    IMAGE_NAME=kali-nethunter-rootfs-${wimg}-${SYS_ARCH}.tar.xz
    SHA_NAME=${IMAGE_NAME}.sha512sum
}

function prepare_fs() {
    printf "${blue}[+] Preparing filesystem...${reset}\n"
    [ -d ${CHROOT} ] && rm -rf ${CHROOT}
}

function cleanup() {
    printf "${blue}[+] Cleaning up...${reset}\n"
    [ -f "${IMAGE_NAME}" ] && rm -f "${IMAGE_NAME}" "${SHA_NAME}"
}

function check_dependencies() {
    printf "${blue}[+] Checking and installing dependencies...${reset}\n"
    apt update -y && apt install -y proot tar wget || {
        printf "${red}[!] Dependency installation failed.${reset}\n"
        exit 1
    }
}

function get_rootfs() {
    printf "${blue}[+] Downloading NetHunter rootfs...${reset}\n"
    wget -q --show-progress "${BASE_URL}/${IMAGE_NAME}" || {
        printf "${red}[!] Failed to download ${IMAGE_NAME}. Retrying...${reset}\n"
        wget -q --show-progress "${BASE_URL}/${IMAGE_NAME}"
    }
    wget -q --show-progress "${BASE_URL}/${SHA_NAME}" || {
        printf "${red}[!] Failed to download ${SHA_NAME}. Retrying...${reset}\n"
        wget -q --show-progress "${BASE_URL}/${SHA_NAME}"
    }
}

function verify_sha() {
    printf "${blue}[+] Verifying rootfs integrity...${reset}\n"
    if ! sha512sum -c "${SHA_NAME}"; then
        printf "${red}[!] Integrity check failed. Re-downloading files.${reset}\n"
        rm -f "${IMAGE_NAME}" "${SHA_NAME}"
        get_rootfs
        sha512sum -c "${SHA_NAME}" || {
            printf "${red}[!] Integrity check failed again. Exiting.${reset}\n"
            exit 1
        }
    fi
}

function extract_rootfs() {
    printf "${blue}[+] Extracting rootfs...${reset}\n"
    proot --link2symlink tar -xf "${IMAGE_NAME}"
}

function create_launcher() {
    printf "${blue}[+] Creating launcher...${reset}\n"
    cat > "${PREFIX}/bin/nethunter" <<- EOF
#!/data/data/com.termux/files/usr/bin/bash -e
unset LD_PRELOAD
proot --link2symlink -0 -r ${CHROOT} -b /dev -b /proc -b /sdcard -w /root /usr/bin/env -i HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin TERM=\$TERM /bin/bash --login
EOF
    chmod 700 "${PREFIX}/bin/nethunter"
}

function fix_profile() {
    printf "${blue}[+] Fixing rootfs profile...${reset}\n"
    echo "nameserver 8.8.8.8" > "${CHROOT}/etc/resolv.conf"
}

function print_banner() {
    printf "${green}[=] Kali NetHunter installed successfully!${reset}\n"
    printf "${green}[+] Use 'nethunter' to start.${reset}\n"
}

# Main execution
print_banner
get_arch
set_strings
prepare_fs
check_dependencies
get_rootfs
verify_sha
extract_rootfs
create_launcher
cleanup
fix_profile
print_banner

#!/bin/bash
# File: install_proot_x11.sh
# Description: One-click installer for Proot Distro with Termux-X11 desktop.

# Exit on error
set -e

# Define constants
DISTRO="ubuntu"
DESKTOP_ENV="lxde"
PROOT_BIN="/data/data/com.termux/files/usr/bin/proot-distro"
TERMUX_X11_REPO="https://github.com/termux/termux-x11"

echo "Updating Termux packages..."
pkg update -y && pkg upgrade -y

echo "Installing dependencies..."
pkg install -y x11-repo proot proot-distro pulseaudio termux-x11-nightly wget git

# Check if Proot Distro is installed
if [ ! -f "$PROOT_BIN" ]; then
    echo "Installing proot-distro..."
    pkg install proot-distro -y
fi

echo "Setting up $DISTRO distribution..."
proot-distro install $DISTRO

echo "Configuring $DISTRO..."
proot-distro login $DISTRO -- bash -c "
apt update && apt upgrade -y
apt install -y $DESKTOP_ENV xserver-xorg-core dbus-x11 xfce4-terminal
"

echo "Installing Termux-X11..."
if [ ! -d "termux-x11" ]; then
    git clone "$TERMUX_X11_REPO"
    cd termux-x11
    ./build.sh
    cd ..
fi

echo "Configuring seamless desktop environment..."
echo "export DISPLAY=:0" >> ~/.bashrc
echo "export PULSE_SERVER=127.0.0.1" >> ~/.bashrc
source ~/.bashrc

echo "Creating launch script..."
cat << EOF > start-distro.sh
#!/bin/bash
# Launch the Linux desktop in Proot with Termux-X11

pulseaudio --start
termux-x11 :0 &
sleep 5

proot-distro login $DISTRO -- bash -c "startx"
EOF

chmod +x start-distro.sh

echo "Installation complete! To start the desktop, run: ./start-distro.sh"

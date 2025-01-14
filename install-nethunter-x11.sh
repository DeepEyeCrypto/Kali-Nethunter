#!/bin/bash

# Update and upgrade Termux packages
pkg update -y && pkg upgrade -y

# Install necessary packages
pkg install -y proot-distro x11-repo

# Install Ubuntu Proot-Distro
proot-distro install ubuntu

# Create a script to run Ubuntu
cat << 'EOF' > ~/start-ubuntu.sh
#!/bin/bash
unset LD_PRELOAD
proot-distro login ubuntu
EOF

chmod +x ~/start-ubuntu.sh

# Start Ubuntu and install the desktop environment
~/start-ubuntu.sh << 'EOF'
apt update -y
apt upgrade -y

# Install Ubuntu desktop environment
apt install -y lxde-core lxde-icon-theme dbus-x11

# Set up LXDE to start with an X11 server
echo "#!/bin/bash
export DISPLAY=:0
startlxde" > ~/.xinitrc
chmod +x ~/.xinitrc

# Install and configure dbus
apt install -y dbus
dbus-uuidgen > /var/lib/dbus/machine-id

EOF

# Instructions for the user
echo "Installation completed. You can start the Ubuntu environment by running:"
echo "~/start-ubuntu.sh"
echo "Then start the X11 server in Termux by running:"
echo "startx"
echo "You can then access the LXDE desktop environment directly on your device."

# End of script

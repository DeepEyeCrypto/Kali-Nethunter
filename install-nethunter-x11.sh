#!/bin/bash

# Update and Upgrade System
sudo apt update -y
sudo apt upgrade -y

# Install Desktop Environment and Necessary Packages
sudo apt install -y xfce4 xfce4-goodies xrdp git wget curl pulseaudio plank cairo-dock ruby libinput-tools build-essential

# Enable PulseAudio over Network
sudo systemctl start pulseaudio
sudo pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1

# Install macOS-like Theme and Icons
mkdir -p ~/.themes ~/.icons
cd ~

# macOS GTK Theme
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme
./install.sh -c dark -n nord -t all

# macOS Icon Theme
cd ~
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme
./install.sh

# Set macOS-like Theme and Icons
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-dark"
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur-dark"

# Download macOS Wallpapers
cd ~
wget -O ~/big-sur.jpg https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg

# Set Default Wallpaper
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s ~/big-sur.jpg

# Configure Plank (Dock)
mkdir -p ~/.config/autostart
echo "[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank
Comment=Start Plank on XFCE startup" > ~/.config/autostart/plank.desktop

# Configure Cairo Dock
mkdir -p ~/.config/autostart
echo "[Desktop Entry]
Type=Application
Exec=cairo-dock
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Cairo Dock
Comment=Start Cairo Dock on XFCE startup" > ~/.config/autostart/cairo-dock.desktop

# Install and Configure Fusuma for Gestures
sudo gem install fusuma
mkdir -p ~/.config/fusuma
echo "
swipe:
  3:
    left:
      command: 'xdotool key alt+Right'
    right:
      command: 'xdotool key alt+Left'
    up:
      command: 'xdotool key super'
    down:
      command: 'xdotool key super+Shift'
pinch:
  in:
    command: 'xdotool key ctrl+plus'
  out:
    command: 'xdotool key ctrl+minus'
" > ~/.config/fusuma/config.yml
echo "[Desktop Entry]
Type=Application
Exec=fusuma
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Fusuma
Comment=Start Fusuma for gestures on XFCE startup" > ~/.config/autostart/fusuma.desktop

# Enable XFWM4 Compositing and Customize Panel
xfconf-query -c xfwm4 -p /general/use_compositing -s true
xfconf-query -c xfce4-panel -p /panels/panel-0/position -s "p=8;x=0;y=0"

# macOS-like Keyboard Shortcuts
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Alt>Tab" -s "xfce4-appfinder --collapsed"
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>Space" -s "xfce4-appfinder"

# Reboot System
echo "Setup complete. Please reboot your system to apply all changes."

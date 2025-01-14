#!/bin/bash

# Function to update and install necessary packages
setup_environment() {
    echo "[*] Updating and upgrading Termux packages..."
    pkg update -y && pkg upgrade -y

    echo "[*] Installing required packages..."
    pkg install -y wget proot tar pulseaudio termux-x11 xfce4-session tigervnc openbox
}

# Function to install Kali Linux
install_kali_linux() {
    echo "[*] Downloading and setting up Kali Linux (Nethunter)..."
    wget -O install-nethunter-termux https://offs.ec/2MceZWr
    chmod +x install-nethunter-termux
    ./install-nethunter-termux
}

# Function to configure VNC and GUI
configure_vnc() {
    echo "[*] Configuring VNC with XFCE desktop environment..."
    mkdir -p ~/.vnc
    cat <<EOF > ~/.vnc/xstartup
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
EOF
    chmod +x ~/.vnc/xstartup
}

# Function to set up audio with Pulseaudio
setup_audio() {
    echo "[*] Setting up Pulseaudio for audio forwarding..."
    pulseaudio --start
}

# Function to start Termux-X11 and Kali Linux
start_kali_gui() {
    echo "[*] Starting Termux X11 server..."
    termux-x11 :1 &

    echo "[*] Launching Kali Linux with XFCE GUI..."
    nethunter kex &
}

# Execute all functions
setup_environment
install_kali_linux
configure_vnc
setup_audio
start_kali_gui

# Final message
echo "[*] Setup complete!"
echo "Open Termux X11 or VNC Viewer with 'localhost:1' to access the Kali Linux GUI."

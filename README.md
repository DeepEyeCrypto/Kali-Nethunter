# Ubuntu-Proot

# Termux-X11 Proot Distro Installer

## Overview
This project provides a one-click script to install and configure a Linux desktop environment on Android using Termux, Proot-Distro, and Termux-X11. It sets up a seamless LXDE desktop environment for productivity or experimentation.

## Features
- **One-click installation**: Automates the setup process for Proot and Termux-X11.
- **Seamless desktop**: Configures an LXDE desktop environment with X11 support.
- **Customizable**: Easy to modify for different Linux distributions or desktop environments.
- **Minimal dependencies**: Installs only what's necessary for a smooth experience.

## Prerequisites
Before running the script, ensure you have:
1. **Termux** installed on your Android device.
2. Internet connection for downloading required packages.
3. At least **2GB of free space** for the installation.

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/DeepEyeCrypto/Ubuntu-Proot.git
   cd termux-x11-proot
   chmod +x install_proot_x11.sh start-distro.sh
   ./install_proot_x11.sh
   ./start-distro.sh
   

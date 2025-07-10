#!/bin/sh

ROOTFS_DIR=$(pwd)/freeroot
mkdir -p "$ROOTFS_DIR"
export PATH=$PATH:~/.local/usr/bin
max_retries=5
timeout=5
ARCH=$(uname -m)

# Set architecture
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  echo "Unsupported CPU architecture: ${ARCH}"
  exit 1
fi

# Confirm install
if [ ! -f "$ROOTFS_DIR/.installed" ]; then
  echo "Foxytoux INSTALLER"
  echo "Installing Ubuntu 24.04 LTS in a contained PRoot..."

  read -p "Continue with installation? (yes/NO): " confirm
  case $confirm in
    [yY][eE][sS])
      echo "[*] Downloading rootfs..."
      wget -q --tries=$max_retries --timeout=$timeout -O /tmp/rootfs.tar.gz \
        "http://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04-base-${ARCH_ALT}.tar.gz" || {
        echo "Download failed."; exit 1; }
      tar -xf /tmp/rootfs.tar.gz -C "$ROOTFS_DIR"
      ;;
    *)
      echo "Aborted by user."
      exit 0
      ;;
  esac
fi

# Install proot binary
if [ ! -x "$ROOTFS_DIR/usr/local/bin/proot" ]; then
  echo "[*] Installing PRoot..."
  mkdir -p "$ROOTFS_DIR/usr/local/bin"
  wget -q -O "$ROOTFS_DIR/usr/local/bin/proot" \
    "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"
  chmod +x "$ROOTFS_DIR/usr/local/bin/proot"
fi

# Setup DNS
echo "nameserver 1.1.1.1" > "$ROOTFS_DIR/etc/resolv.conf"
echo "nameserver 1.0.0.1" >> "$ROOTFS_DIR/etc/resolv.conf"

# Mark as installed
touch "$ROOTFS_DIR/.installed"

# Launch PRoot safely
echo "[*] Starting Ubuntu in PRoot..."
"$ROOTFS_DIR/usr/local/bin/proot" \
  --rootfs="$ROOTFS_DIR" \
  -0 -w "/root" -b /dev -b /proc -b /sys -b "$HOME" -b /etc/resolv.conf \
  /bin/bash || echo "Failed to start bash inside rootfs."

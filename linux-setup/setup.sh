#!/usr/bin/env bash
# Sets up a fresh Linux install with Firefox and Steam.
# Supports Ubuntu, Linux Mint, Pop!_OS, Debian and Fedora.
# Safe to re-run: steps that are already done are skipped.
#
# Usage:  bash setup.sh
set -euo pipefail

say()  { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
warn() { printf '\n\033[1;33m!!  %s\033[0m\n' "$*"; }
die()  { printf '\n\033[1;31mXX  %s\033[0m\n' "$*"; exit 1; }

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  command -v sudo >/dev/null || die "sudo is not installed; run this as root instead."
  SUDO="sudo"
fi

[ -r /etc/os-release ] || die "Can't detect your Linux distro (/etc/os-release missing)."
. /etc/os-release
FAMILY="${ID} ${ID_LIKE:-}"

has_nvidia() {
  command -v lspci >/dev/null && lspci | grep -iE 'vga|3d|display' | grep -qi nvidia
}

setup_debian_family() {
  export DEBIAN_FRONTEND=noninteractive

  say "Updating the system"
  $SUDO apt-get update
  $SUDO apt-get -y upgrade
  $SUDO apt-get install -y software-properties-common pciutils wget ca-certificates

  say "Installing Firefox"
  if command -v firefox >/dev/null; then
    echo "Firefox is already installed."
  else
    $SUDO apt-get install -y firefox || $SUDO apt-get install -y firefox-esr
  fi

  say "Installing Steam"
  # Steam needs 32-bit libraries, and on Ubuntu it lives in the 'multiverse' repo.
  $SUDO dpkg --add-architecture i386
  if [ "$ID" = "ubuntu" ]; then
    $SUDO add-apt-repository -y multiverse
  fi
  $SUDO apt-get update
  if command -v steam >/dev/null; then
    echo "Steam is already installed."
  elif ! $SUDO apt-get install -y steam-installer && ! $SUDO apt-get install -y steam; then
    warn "Steam isn't in your distro's repos; using Valve's official package instead."
    tmp="$(mktemp -d)"
    wget -O "$tmp/steam.deb" https://repo.steampowered.com/steam/archive/stable/steam_latest.deb
    $SUDO apt-get install -y "$tmp/steam.deb"
    rm -rf "$tmp"
  fi

  if has_nvidia; then
    say "NVIDIA graphics card found: installing the recommended driver"
    if command -v ubuntu-drivers >/dev/null || $SUDO apt-get install -y ubuntu-drivers-common; then
      $SUDO ubuntu-drivers install
      NEEDS_REBOOT=1
    else
      warn "Couldn't install the NVIDIA driver automatically. Use your distro's 'Driver Manager' app."
    fi
  fi
}

setup_fedora() {
  say "Updating the system"
  $SUDO dnf -y upgrade

  say "Installing Firefox"
  $SUDO dnf -y install firefox

  say "Enabling RPM Fusion (needed for Steam and NVIDIA drivers)"
  fedora_ver="$(rpm -E %fedora)"
  $SUDO dnf -y install \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm"

  say "Installing Steam"
  $SUDO dnf -y install steam

  if has_nvidia; then
    say "NVIDIA graphics card found: installing the driver"
    $SUDO dnf -y install akmod-nvidia xorg-x11-drv-nvidia-cuda
    warn "The driver builds in the background for a few minutes. Wait ~5 minutes before rebooting."
    warn "If Secure Boot is on in your BIOS, the driver may not load. Turning Secure Boot off is the simple fix."
    NEEDS_REBOOT=1
  fi
}

NEEDS_REBOOT=0
case "$FAMILY" in
  *fedora*)              setup_fedora ;;
  *debian*|*ubuntu*)     setup_debian_family ;;
  *) die "Unsupported distro: ${PRETTY_NAME:-$ID}. Use Ubuntu, Linux Mint or Fedora." ;;
esac

say "All done!"
cat <<'EOF'
Next steps:
  1. Open Steam and log in. Your games will be listed under Library.
  2. For Windows-only games: Steam > Settings > Compatibility >
     turn on "Enable Steam Play for all other titles" (this uses Proton).
  3. Check a game's Linux support at https://www.protondb.com
EOF
if [ "$NEEDS_REBOOT" -eq 1 ]; then
  warn "Reboot your computer to finish installing the graphics driver."
fi

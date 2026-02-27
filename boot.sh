#!/bin/bash

# Ensure HOME is set correctly (sudo -u doesn't always set it)
export HOME=$(getent passwd "$(whoami)" | cut -d: -f6)

# Set install mode to online since boot.sh is used for curl installations
export OMARCHY_ONLINE_INSTALL=true

ansi_art='                 ▄▄▄
 ▄█████▄    ▄███████████▄    ▄███████   ▄███████   ▄███████   ▄█   █▄    ▄█   █▄
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   █▀   ███   ███  ███   ███
███   ███  ███   ███   ███ ▄███▄▄▄███ ▄███▄▄▄██▀  ███       ▄███▄▄▄███▄ ███▄▄▄███
███   ███  ███   ███   ███ ▀███▀▀▀███ ▀███▀▀▀▀    ███      ▀▀███▀▀▀███  ▀▀▀▀▀▀███
███   ███  ███   ███   ███  ███   ███ ██████████  ███   █▄   ███   ███  ▄██   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
 ▀█████▀    ▀█   ███   █▀   ███   █▀   ███   ███  ███████▀   ███   █▀    ▀█████▀
                                       ███   █▀                                  '

clear
echo -e "\n$ansi_art\n"

# Use custom branch if instructed, otherwise default to master
OMARCHY_REF="${OMARCHY_REF:-master}"

# Set mirror based on branch (omarchy mirrors are x86_64-only, skip on aarch64)
if [[ $(uname -m) == "aarch64" ]]; then
  echo "aarch64 detected — setting up ALARM package management..."

  # Deploy clean ALARM pacman config FIRST (overwrites any stale config from previous installs)
  sudo tee /etc/pacman.conf >/dev/null <<'PACMANCONF'
[options]
HoldPkg = pacman glibc
Architecture = aarch64
CheckSpace
ParallelDownloads = 5
DownloadUser = alpm
SigLevel = Required DatabaseOptional
LocalFileSigLevel = Optional

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[alarm]
Include = /etc/pacman.d/mirrorlist
PACMANCONF

  sudo tee /etc/pacman.d/mirrorlist >/dev/null <<'MIRRORLIST'
Server = http://dk.mirror.archlinuxarm.org/$arch/$repo
Server = http://de.mirror.archlinuxarm.org/$arch/$repo
Server = http://fl.us.mirror.archlinuxarm.org/$arch/$repo
Server = http://ca.us.mirror.archlinuxarm.org/$arch/$repo
Server = http://sg.mirror.archlinuxarm.org/$arch/$repo
MIRRORLIST

  # Verify config was written correctly — no stale omarchy/multilib references
  if grep -qE "omarchy|multilib" /etc/pacman.conf 2>/dev/null; then
    echo "ERROR: pacman.conf still contains omarchy/multilib references!"
    cat /etc/pacman.conf
    exit 1
  fi

  # Wipe ALL stale sync DBs (may contain omarchy.db/multilib.db from previous failed runs)
  sudo rm -rf /var/lib/pacman/sync/*

  # Diagnostics: show config + sync state before first pacman call
  echo "--- pacman.conf repos ---"
  grep '^\[' /etc/pacman.conf
  echo "--- sync DBs ---"
  ls /var/lib/pacman/sync/ 2>/dev/null || echo "(empty)"
  echo "--- mirrorlist ---"
  cat /etc/pacman.d/mirrorlist
  echo "-------------------------"

  # Initialize keyring and populate ALARM keys BEFORE any pacman operations
  sudo pacman-key --init
  sudo pacman-key --populate archlinuxarm

  # Single sync + keyring install
  sudo pacman -Syy --noconfirm --needed archlinuxarm-keyring
elif [[ $OMARCHY_REF == "dev" ]]; then
  export OMARCHY_MIRROR=edge
  echo 'Server = https://mirror.omarchy.org/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
elif [[ $OMARCHY_REF == "rc" ]]; then
  export OMARCHY_MIRROR=rc
  echo 'Server = https://rc-mirror.omarchy.org/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
else
  export OMARCHY_MIRROR=stable
  echo 'Server = https://stable-mirror.omarchy.org/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
fi

# On aarch64 we already synced in the block above; on x86_64 the mirror was just set.
# Only install git here (needed for clone below). Full upgrade happens in preflight/pacman.sh.
if [[ $(uname -m) == "aarch64" ]]; then
  sudo pacman -S --noconfirm --needed git base-devel
else
  sudo pacman -Syu --noconfirm --needed git base-devel
fi

# Use custom repo if specified, otherwise default to basecamp/omarchy
OMARCHY_REPO="${OMARCHY_REPO:-basecamp/omarchy}"

echo -e "\nCloning Omarchy from: https://github.com/${OMARCHY_REPO}.git"
rm -rf ~/.local/share/omarchy/
git clone "https://github.com/${OMARCHY_REPO}.git" ~/.local/share/omarchy >/dev/null

echo -e "\e[32mUsing branch: $OMARCHY_REF\e[0m"
cd ~/.local/share/omarchy
git fetch origin "${OMARCHY_REF}" && git checkout "${OMARCHY_REF}"
cd -

echo -e "\nInstallation starting..."
source ~/.local/share/omarchy/install.sh

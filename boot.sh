#!/bin/bash

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

  # Initialize keyring before any pacman operations
  sudo pacman-key --init
  sudo pacman-key --populate

  # Ensure we have working ALARM mirrors for the initial pacman sync
  if ! grep -q "archlinuxarm.org" /etc/pacman.d/mirrorlist 2>/dev/null; then
    echo 'Server = http://dk.mirror.archlinuxarm.org/$arch/$repo' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
    echo 'Server = http://de.mirror.archlinuxarm.org/$arch/$repo' | sudo tee -a /etc/pacman.d/mirrorlist >/dev/null
  fi

  # Install ALARM keyring and populate
  sudo pacman -Sy --noconfirm --needed archlinuxarm-keyring
  sudo pacman-key --populate archlinuxarm
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

sudo pacman -Syu --noconfirm --needed git base-devel

# Use custom repo if specified, otherwise default to basecamp/omarchy
OMARCHY_REPO="${OMARCHY_REPO:-basecamp/omarchy}"

echo -e "\nCloning Omarchy from: https://github.com/${OMARCHY_REPO}.git"
rm -rf ~/.local/share/omarchy/
git clone "https://github.com/${OMARCHY_REPO}.git" ~/.local/share/omarchy >/dev/null

echo -e "\e[32mUsing branch: $OMARCHY_REF\e[0m"
cd ~/.local/share/omarchy
git fetch origin "${OMARCHY_REF}" && git checkout "${OMARCHY_REF}"
cd -

# aarch64: deploy proper mirrorlist + pacman.conf from repo
if [[ $(uname -m) == "aarch64" ]] && [[ -d ~/.local/share/omarchy/install/aarch64 ]]; then
  echo "Deploying aarch64 pacman configuration from repo..."
  sudo cp ~/.local/share/omarchy/install/aarch64/mirrorlist /etc/pacman.d/mirrorlist
  sudo cp ~/.local/share/omarchy/install/aarch64/pacman.conf /etc/pacman.conf
  sudo pacman -Sy --noconfirm
fi

echo -e "\nInstallation starting..."
source ~/.local/share/omarchy/install.sh

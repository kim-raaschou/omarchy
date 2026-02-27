if [[ -n ${OMARCHY_ONLINE_INSTALL:-} ]]; then
  if [[ $(uname -m) == "aarch64" ]]; then
    # aarch64: deploy ALARM pacman config BEFORE any pacman operations
    echo "Deploying ALARM pacman config..."
    sudo cp -f ~/.local/share/omarchy/install/aarch64/pacman.conf /etc/pacman.conf
    sudo cp -f ~/.local/share/omarchy/install/aarch64/mirrorlist /etc/pacman.d/mirrorlist

    # Remove all stale sync DBs — fresh -Syy will re-download
    sudo rm -rf /var/lib/pacman/sync/*

    # Force-refresh all package databases
    sudo pacman -Syy --noconfirm

    # Install build tools (needed for AUR builds later)
    omarchy-pkg-add base-devel

    # Full system upgrade
    sudo pacman -Suu --noconfirm

    # Bootstrap yay (AUR helper) — not in ALARM repos, download pre-built aarch64 binary
    if ! command -v yay &>/dev/null; then
      echo "Bootstrapping yay (AUR helper)..."
      YAY_VERSION=$(curl -s https://api.github.com/repos/Jguer/yay/releases/latest | grep -Po '"tag_name": "v\K[^"]+')
      curl -Lo /tmp/yay.tar.gz "https://github.com/Jguer/yay/releases/download/v${YAY_VERSION}/yay_${YAY_VERSION}_aarch64.tar.gz"
      tar xzf /tmp/yay.tar.gz -C /tmp
      sudo install -m755 "/tmp/yay_${YAY_VERSION}_aarch64/yay" /usr/bin/yay
      rm -rf /tmp/yay*
      echo "yay ${YAY_VERSION} installed."
    fi
  else
    # x86_64: install build tools first, then configure omarchy mirror
    omarchy-pkg-add base-devel

    sudo cp -f ~/.local/share/omarchy/default/pacman/pacman-${OMARCHY_MIRROR:-stable}.conf /etc/pacman.conf
    sudo cp -f ~/.local/share/omarchy/default/pacman/mirrorlist-${OMARCHY_MIRROR:-stable} /etc/pacman.d/mirrorlist

    sudo pacman-key --recv-keys 40DFB630FF42BCFFB047046CF0134EE680CAC571 --keyserver keys.openpgp.org
    sudo pacman-key --lsign-key 40DFB630FF42BCFFB047046CF0134EE680CAC571

    sudo pacman -Sy
    omarchy-pkg-add omarchy-keyring

    # Refresh all repos
    sudo pacman -Syyuu --noconfirm
  fi
fi

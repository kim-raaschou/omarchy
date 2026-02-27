abort() {
  echo -e "\e[31mOmarchy install requires: $1\e[0m"
  echo
  gum confirm "Proceed anyway on your own accord and without assistance?" || exit 1
}

# Must be an Arch distro
if [[ ! -f /etc/arch-release ]]; then
  abort "Vanilla Arch"
fi

# Must not be an Arch derivative distro
for marker in /etc/cachyos-release /etc/eos-release /etc/garuda-release /etc/manjaro-release; do
  if [[ -f $marker ]]; then
    abort "Vanilla Arch"
  fi
done

# Must not run as root
if (( EUID == 0 )); then
  abort "Running as root (not user)"
fi

# Must be x86_64 or aarch64
if [[ $(uname -m) != "x86_64" ]] && [[ $(uname -m) != "aarch64" ]]; then
  abort "x86_64 or aarch64 CPU"
fi

# Must have secure boot disabled (skip on aarch64 — no bootctl)
if [[ $(uname -m) != "aarch64" ]]; then
  if bootctl status 2>/dev/null | grep -q 'Secure Boot: enabled'; then
    abort "Secure Boot disabled"
  fi
fi

# Must not have Gnome or KDE already installed
if pacman -Qe gnome-shell &>/dev/null || pacman -Qe plasma-desktop &>/dev/null; then
  abort "Fresh + Vanilla Arch"
fi

# Limine and btrfs checks only on x86_64 (aarch64 uses different bootloaders/filesystems)
if [[ $(uname -m) != "aarch64" ]]; then
  command -v limine &>/dev/null || abort "Limine bootloader"
  [[ $(findmnt -n -o FSTYPE /) = "btrfs" ]] || abort "Btrfs root filesystem"
fi

# Cleared all guards
echo "Guards: OK"

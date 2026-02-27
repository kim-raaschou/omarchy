# Configure pacman
arch_suffix=""
[[ "$(uname -m)" == "aarch64" ]] && arch_suffix="-aarch64"

sudo cp -f ~/.local/share/omarchy/default/pacman/pacman-${OMARCHY_MIRROR:-stable}${arch_suffix}.conf /etc/pacman.conf
sudo cp -f ~/.local/share/omarchy/default/pacman/mirrorlist-${OMARCHY_MIRROR:-stable}${arch_suffix} /etc/pacman.d/mirrorlist

if lspci -nn | grep -q "106b:180[12]"; then
  cat <<EOF | sudo tee -a /etc/pacman.conf >/dev/null

[arch-mact2]
Server = https://github.com/NoaHimesaka1873/arch-mact2-mirror/releases/download/release
SigLevel = Never
EOF
fi

# aarch64 VM: enable software rendering for Hyprland
# Most aarch64 VMs (UTM/QEMU) lack hardware GPU acceleration.
# pixman provides CPU-based rendering as a fallback.
#
# CRITICAL: WLR_RENDERER must be set BEFORE Hyprland starts (wlroots reads it
# at init time). Setting it in hyprland.conf is too late. We set it in:
# 1. uwsm env file (read before session launch)
# 2. /etc/environment (fallback for non-uwsm launches)

if [[ "$(uname -m)" != "aarch64" ]]; then
  return 0
fi

# Only apply if running in a VM (detect virtio/QEMU/KVM)
if ! systemd-detect-virt -q 2>/dev/null; then
  return 0
fi

echo "aarch64 VM detected — configuring software rendering for Hyprland..."

# 1. uwsm env file — sets env vars BEFORE Hyprland is launched by uwsm
UWSM_ENV="$HOME/.config/uwsm/env"
mkdir -p "$(dirname "$UWSM_ENV")"
if ! grep -q "WLR_RENDERER" "$UWSM_ENV" 2>/dev/null; then
  cat >> "$UWSM_ENV" <<'EOF'
# aarch64 VM: software rendering (no hardware GPU)
export WLR_RENDERER=pixman
export WLR_NO_HARDWARE_CURSORS=1
export LIBGL_ALWAYS_SOFTWARE=1
EOF
  echo "Added software rendering env vars to $UWSM_ENV"
fi

# 2. /etc/environment — fallback for direct launches
if ! grep -q "WLR_RENDERER" /etc/environment 2>/dev/null; then
  cat <<'EOF' | sudo tee -a /etc/environment >/dev/null
WLR_RENDERER=pixman
WLR_NO_HARDWARE_CURSORS=1
LIBGL_ALWAYS_SOFTWARE=1
EOF
  echo "Added software rendering env vars to /etc/environment"
fi

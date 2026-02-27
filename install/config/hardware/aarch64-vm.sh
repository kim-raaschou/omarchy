# aarch64 VM: enable software rendering for Hyprland
# Most aarch64 VMs (UTM/QEMU) lack hardware GPU acceleration.
# pixman provides CPU-based rendering as a fallback.

if [[ "$(uname -m)" != "aarch64" ]]; then
  return 0
fi

# Only apply if running in a VM (detect virtio/QEMU/KVM)
if ! systemd-detect-virt -q 2>/dev/null; then
  return 0
fi

echo "aarch64 VM detected — configuring software rendering for Hyprland..."

# Add env vars to user hyprland config (env directives work anywhere in the config)
HYPR_ENV_FILE="$HOME/.config/hypr/autostart.conf"

if ! grep -q "WLR_RENDERER" "$HYPR_ENV_FILE" 2>/dev/null; then
  cat >> "$HYPR_ENV_FILE" <<'EOF'

# aarch64 VM: software rendering (no hardware GPU)
env = WLR_RENDERER,pixman
env = WLR_NO_HARDWARE_CURSORS,1
env = LIBGL_ALWAYS_SOFTWARE,1
EOF
  echo "Added software rendering env vars to $HYPR_ENV_FILE"
fi

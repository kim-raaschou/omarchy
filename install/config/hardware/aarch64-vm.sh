# aarch64: enable software rendering for Hyprland
# aarch64 systems often lack hardware GPU acceleration (VMs, some SBCs).
# pixman provides CPU-based rendering as a fallback.
# On bare metal with proper GPU (e.g. Asahi), remove these env vars manually.
#
# CRITICAL: WLR_RENDERER must be set BEFORE Hyprland starts (wlroots reads it
# at init time). Setting it in hyprland.conf is too late. We set it in:
# 1. uwsm env file (read before session launch)
# 2. /etc/environment (fallback for non-uwsm launches)

if [[ "$(uname -m)" != "aarch64" ]]; then
  return 0
fi

echo "aarch64 detected — configuring software rendering for Hyprland..."

# 1. uwsm env file — sets env vars BEFORE Hyprland is launched by uwsm
UWSM_ENV="$HOME/.config/uwsm/env"
mkdir -p "$(dirname "$UWSM_ENV")"
if ! grep -q "WLR_RENDERER" "$UWSM_ENV" 2>/dev/null; then
  cat >> "$UWSM_ENV" <<'EOF'
# aarch64: software rendering (no hardware GPU)
export WLR_RENDERER=pixman
export WLR_NO_HARDWARE_CURSORS=1
export LIBGL_ALWAYS_SOFTWARE=1
EOF
  echo "Added software rendering env vars to $UWSM_ENV"
fi

# 2. /etc/environment — fallback for direct launches and SDDM sessions
if ! grep -q "WLR_RENDERER" /etc/environment 2>/dev/null; then
  cat <<'EOF' | sudo tee -a /etc/environment >/dev/null
WLR_RENDERER=pixman
WLR_NO_HARDWARE_CURSORS=1
LIBGL_ALWAYS_SOFTWARE=1
EOF
  echo "Added software rendering env vars to /etc/environment"
fi

# 3. Wrapper script — guarantees env vars are set regardless of how SDDM
#    handles session launch (PAM may not read /etc/environment on auto-login)
sudo tee /usr/local/bin/hyprland-direct >/dev/null <<'WRAPPER'
#!/bin/bash
export WLR_RENDERER=pixman
export WLR_NO_HARDWARE_CURSORS=1
export LIBGL_ALWAYS_SOFTWARE=1
exec Hyprland "$@"
WRAPPER
sudo chmod +x /usr/local/bin/hyprland-direct
echo "Created /usr/local/bin/hyprland-direct wrapper"

# 4. Create a direct Hyprland session (bypasses uwsm which may fail on aarch64)
# The stock hyprland.desktop uses start-hyprland/uwsm which can cause login loops.
sudo tee /usr/share/wayland-sessions/hyprland-direct.desktop >/dev/null <<'EOF'
[Desktop Entry]
Name=Hyprland (Direct)
Comment=Hyprland compositor — direct launch for aarch64
Exec=/usr/local/bin/hyprland-direct
Type=Application
EOF
echo "Created direct Hyprland session (hyprland-direct.desktop)"

# Includes lazyvim and the themes
# omarchy-nvim-setup is provided by the omarchy-nvim package (custom mirror).
# On aarch64 (no omarchy mirror), skip if the command is not available.
if command -v omarchy-nvim-setup &>/dev/null; then
  omarchy-nvim-setup
fi

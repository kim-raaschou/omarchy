if pacman -Q kernel-modules-hook &>/dev/null; then
  chrootable_systemctl_enable linux-modules-cleanup.service
fi

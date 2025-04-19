#!/usr/bin/env sh

# Thanks to bri for the inspiration! My script is based on this example:
# https://github.com/briorg/bluefin/blob/c62c30a04d42fd959ea770722c6b51216b4ec45b/scripts/1password.sh

set -ouex pipefail

echo "Installing Taiscale"

# On libostree systems, /opt is a symlink to /var/opt,
# which actually only exists on the live system. /var is
# a separate mutable, stateful FS that's overlaid onto
# the ostree rootfs. Therefore we need to install it into
# /usr/lib/google instead, and dynamically create a
# symbolic link /opt/google => /usr/lib/google upon
# boot.

# Prepare staging directory
# mkdir -p /var/opt # -p just in case it exists

# Prepare alternatives directory
# mkdir -p /var/lib/alternatives

# Setup repo
sudo curl -s https://pkgs.tailscale.com/stable/fedora/tailscale.repo -o /etc/yum.repos.d/tailscale.repo
sudo sed -i 's/repo_gpgcheck=1/repo_gpgcheck=0/' /etc/yum.repos.d/tailscale.repo
sudo rpm-ostree install --apply-live tailscale

sudo systemctl enable --now tailscaled
# Clean up the yum repo (updates are baked into new images)
# rm /etc/yum.repos.d/tailscale.repo -f


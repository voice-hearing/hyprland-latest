#!/usr/bin/bash

set -ouex pipefail

# github direct installs
  rpm-ostree install \
      https://github.com/twpayne/chezmoi/releases/download/v2.61.0/chezmoi-2.61.0-x86_64.rpm
# Starship Shell Prompt
curl -Lo /tmp/starship.tar.gz "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz"
tar -xzf /tmp/starship.tar.gz -C /tmp
install -c -m 0755 /tmp/starship /usr/bin
# shellcheck disable=SC2016
echo 'eval "$(starship init bash)"' >> /etc/bashrc

# Bash Prexec
curl -Lo /usr/share/bash-prexec https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh

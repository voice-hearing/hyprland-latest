#!/usr/bin/env bash

set ${SET_X:+-x} -eou pipefail

# Set default value if IMAGE is not defined
IMAGE=${IMAGE:-fedora}

# Example usage of the IMAGE variable
echo "Building Docker image with name: $IMAGE"
docker build -t "$IMAGE" 

# Setup repo
cat <<EOF >/etc/yum.repos.d/docker-ce.repo
[docker-ce-stable]
name=Docker CE Stable
baseurl=https://download.docker.com/linux/fedora/\$releasever/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/fedora/gpg
EOF

if [[ $FEDORA_MAJOR_VERSION -eq 42 ]]; then
    dnf install -y --enablerepo=docker-ce-testing docker-ce docker-buildx-plugin docker-ce-cli docker-compose-plugin
fi

# prefer to have docker-compose available for legacy muscle-memory
ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose

# Docker sysctl.d
mkdir -p /usr/lib/sysctl.d
echo "net.ipv4.ip_forward = 1" >/usr/lib/sysctl.d/docker-ce.conf

# disable repo
sed -i "s@enabled=1@enabled=0@" /etc/yum.repos.d/docker-ce.repo

#!/bin/sh
# Adapted from https://piware.de/gitweb/?p=bin.git;a=blob_plain;f=build-debian-toolbox
# Thanks Martin Pitt!
# This script mostly works for cli tools but systemd fails on installation for other things

set -eux

# See https://gallery.ecr.aws/ubuntu/ubuntu for list of releases
FROM registry.fedoraproject.org/fedora-toolbox:42 AS fedora-toolbox

LABEL com.github.containers.toolbox="true" \
      usage="This image is meant to be used with the toolbox or distrobox command" \
      summary="A cloud-native terminal experience powered by Fedora" 

COPY ./toolboxes/fedora-toolbox/packages.fedora /tmp/toolbox-packages

# First upgrade the system and install dnf5
RUN dnf -y upgrade && \
    dnf -y install dnf5 dnf5-plugins && \
    # Set dnf5 as default and clean old dnf cache
    ln -sf /usr/bin/dnf5 /usr/bin/dnf && \
    ln -sf /usr/bin/dnf5 /usr/bin/yum && \
    dnf clean all

# Install main packages using dnf5
RUN dnf -y install $(<tmp/toolbox-packages) && \
    dnf clean all

# Set up dependencies
RUN git clone https://github.com/89luca89/distrobox.git --single-branch /tmp/distrobox && \
    cp /tmp/distrobox/distrobox-host-exec /usr/bin/distrobox-host-exec && \
    wget https://github.com/1player/host-spawn/releases/download/$(cat /tmp/distrobox/distrobox-host-exec | grep host_spawn_version= | cut -d "\"" -f 2)/host-spawn-$(uname -m) -O /usr/bin/host-spawn && \
    chmod +x /usr/bin/host-spawn && \
    rm -drf /tmp/distrobox && \
    dnf install -y 'dnf-command(copr)' && \
    dnf clean all

# Set up cleaner Distrobox integration
RUN dnf copr enable -y kylegospo/distrobox-utils && \
    dnf install -y \
    xdg-utils-distrobox \
    adw-gtk3-theme && \
    ln -s /usr/bin/distrobox-host-exec /usr/bin/flatpak && \
    dnf clean all

# Install RPMFusion for hardware accelerated encoding/decoding
RUN dnf install -y \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" && \
    dnf install -y \
    intel-media-driver \
    nvidia-vaapi-driver && \
    dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld && \
    dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld && \
    dnf clean all

# Cleanup
RUN rm -rf /tmp/*

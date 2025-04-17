#!/bin/bash

# Define the path to the RPM package
default_rpm_path="files/scripts/nordvpn*.rpm"

# Function to install Nordvpn
install_nordvpn() {
    local rpm_path=${1:-$default_rpm_path}

    if ls $rpm_path &>/dev/null; then
        echo "Installing nordvpn from $rpm_path using rpm-ostree..."
        sudo rpm-ostree install $rpm_path && echo "Nordvpn installed successfully." || echo "Failed to install Nordvpn."
    else
        echo "No RPM packages found at $rpm_path. Please verify the path."
        exit 1
    fi
}

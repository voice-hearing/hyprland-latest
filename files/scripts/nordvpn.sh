#!/bin/sh

# check for root access
SUDO=
if [ "$(id -u)" -ne 0 ]; then
    SUDO=$(command -v sudo 2> /dev/null)

    if [ ! -x "$SUDO" ]; then
        echo "Error: Run this script as root"
        exit 1
    fi
fi

set -e
ARCH=$(uname -m)
BASE_URL=https://repo.nordvpn.com/
KEY_PATH=/gpg/nordvpn_public.asc
REPO_PATH_RPM=/yum/nordvpn/centos
RELEASE="stable main"
ASSUME_YES=false
# set specific version of nordvpn for rpm-ostree install
# leave it emptu string to install latest version
# should be eg "-3.18.5" to install package nordvpn-3.18.5
NORD_VERSION="-3.18.5"
# Parse command line arguments. Available arguments are:
# -n                Non-interactive mode. With this flag present, 'assume yes' or 
#                   'non-interactive' flags will be passed when installing packages.
# -b <url>          The base URL of the public key and repository locations.
# -k <path>         Path to the public key for the repository.
# -d <path|file>    Repository location for debian packages.
# -v <version>      Debian package version to use.
# -r <path|file>    Repository location for rpm packages.
while getopts 'nb:k:d:r:v:' opt
do
    case $opt in
        n) ASSUME_YES=true ;;
        b) BASE_URL=$OPTARG ;;
        k) KEY_PATH=$OPTARG ;;
        d) REPO_PATH_DEB=$OPTARG ;;
        r) REPO_PATH_RPM=$OPTARG ;;
        v) RELEASE=$OPTARG ;;
        *) ;;
    esac
done

# Construct the paths to the package repository and its key
PUB_KEY=${BASE_URL}${KEY_PATH}
REPO_URL_RPM=${BASE_URL}${REPO_PATH_RPM}

check_cmd() {
    command -v "$1" 2> /dev/null
}

get_install_opts_for_yum() {
    flags=$(get_install_opts_for "yum")
    RETVAL="$flags"
}

get_install_opts_for_dnf() {
    flags=$(get_install_opts_for "dnf")
    RETVAL="$flags"
}

get_install_opts_for_rpm_ostree() {
    flags=$(get_install_opts_for "dnf")
    RETVAL="$flags"
}
    echo ""
}

# For any of the following distributions, these steps are performed:
# 1. Add the NordVPN repository key
# 2. Add the NordVPN repository
# 3. Install NordVPN

# Install NordVPN for Debian, Ubuntu, Elementary OS, and Linux Mint
# (with the apt-get package manager)
# Install NordVPN for RHEL and CentOS
# (with the yum package manager)
# Install NordVPN for rpm-ostree systems
# (with the rpm-ostree package manager)
install_rpm_ostree() {
    DEPENDENCIES="iptables-legacy iptables-legacy-libs iptables-libs libnetfilter_conntrack libnfnetlink"
    TMP_INSTALL_DIR="/tmp/nordvpn_install/"
    TOOLBOX_NAME=$(uuidgen)
    if check_cmd rpm-ostree &> /dev/null; then
        if ! check_cmd curl &> /dev/null; then
            echo "Curl is needed to proceed with the installation"
            exit 1
        fi
        if ! check_cmd toolbox &> /dev/null; then
            echo "the user of this script must be able to create and enter a toolbox to proceed"
            exit 1
        fi
        get_install_opts_for_rpm_ostree
        install_opts="$RETVAL"
        repo="${REPO_URL_RPM}"
        if [ ! -f "${REPO_URL_RPM}" ]; then
            repo="${repo}/${ARCH}"
        fi
	if [ -e ${TMP_INSTALL_DIR} ]; then
            $SUDO rm -rf ${TMP_INSTALL_DIR}
        fi
	mkdir ${TMP_INSTALL_DIR}
        pushd ${TMP_INSTALL_DIR} &>/dev/null
        $SUDO curl ${PUB_KEY} -o /etc/pki/rpm-gpg/RPM-GPG-KEY-nordvpn &>/dev/null
        repo="${REPO_URL_RPM}"
        if [ ! -f "${REPO_URL_RPM}" ]; then
            repo="${repo}/${ARCH}"
        fi
        if [[ $(toolbox list -c |grep -c ${TOOLBOX_NAME}) -eq 0 ]]; then toolbox create -y ${TOOLBOX_NAME} &> /dev/null; fi
	toolbox --container ${TOOLBOX_NAME} run sudo dnf config-manager addrepo --set=baseurl="${repo}" --overwrite
	$SUDO cp /etc/pki/rpm-gpg/RPM-GPG-KEY-nordvpn . &>/dev/null
        toolbox --container ${TOOLBOX_NAME} run sudo rpm --import RPM-GPG-KEY-nordvpn &>/dev/null
        rm -f RPM-GPG-KEY-nordvpn
        toolbox --container ${TOOLBOX_NAME} run sudo dnf download nordvpn &>/dev/null
        rpm_file=$(echo $(find . -maxdepth 1 -name "nordvpn*rpm")) &>/dev/null
  	# mv ${rpm_file} ${TMP_INSTALL_DIR}
	repo_file=$(toolbox --container ${TOOLBOX_NAME} run find /etc/yum.repos.d/ -name "*repo.nordvpn.com*")
	toolbox --container ${TOOLBOX_NAME} run sudo mv ${repo_file} ${TMP_INSTALL_DIR}
        repo_file=${repo_file##*/}
	$SUDO mv ${TMP_INSTALL_DIR}${repo_file} /etc/yum.repos.d/     
        $SUDO rpm-ostree install --idempotent --allow-inactive ${DEPENDENCIES}
	$SUDO rpm-ostree $install_opts install --idempotent nordvpn${NORD_VERSION}
        $SUDO rpm2cpio ${rpm_file} | $SUDO cpio -idmv &>/dev/null
        $SUDO rm ${rpm_file}
        popd
	rm -rf ${TMP_INSTALL_DIR}
        podman stop ${TOOLBOX_NAME}
        toolbox rm ${TOOLBOX_NAME}
	exit
    fi
}

install_yum
install_dnf
install_rpm_ostree

# None of the known package managers (apt, yum, dnf, zypper) are available
echo "Error: Couldn't identify the package manager"
exit 1

#!/usr/bin/env sh

set -ouex pipefail

echo "Installing KopiaUI"

rpm --import https://kopia.io/signing-key

cat <<EOF | tee /etc/yum.repos.d/kopia.repo
[Kopia]
name=Kopia
baseurl=http://packages.kopia.io/rpm/stable/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://kopia.io/signing-key
EOF

rpm-ostree install kopia kopia-ui

rm /etc/yum.repos.d/kopia.repo -f

mv /var/opt/KopiaUI /usr/lib/KopiaUI # move this over here

rm /usr/bin/kopia-ui
ln -s /usr/lib/KopiaUI/kopia-ui /usr/bin/kopia-ui

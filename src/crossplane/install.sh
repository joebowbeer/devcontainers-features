#!/bin/sh
set -e

apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

check_packages ca-certificates curl

echo "Activating feature 'crossplane'"

export XP_VERSION=${VERSION:-"current"}
export XP_CHANNEL=${CHANNEL:-"stable"}

curl -sSL "https://raw.githubusercontent.com/crossplane/crossplane/main/install.sh" | sh

chmod +x crossplane
mv crossplane /usr/local/bin

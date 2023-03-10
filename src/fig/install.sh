#!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

FIG_VERSION=${VERSION:-"latest"}
FIG_CHANNEL=${CHANNEL:-"stable"}
FIG_INTEGRATIONS=${INTEGRATIONS:-"dotfiles,ssh"}

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

apt_get_update()
{
    echo "Running apt-get update..."
    apt-get update -y
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
            apt_get_update
        fi
        apt-get -y install --no-install-recommends "$@"
    fi
}

export DEBIAN_FRONTEND=noninteractive

# Install dependencies
check_packages curl git tar xz-utils

architecture="$(uname -m)"
case $architecture in
    x86_64) architecture="x86_64";;
    aarch64 | armv8* | arm64) architecture="aarch64";;
    *) echo "(!) Architecture $architecture unsupported"; exit 1 ;;
esac

# Use a temporary locaiton for fig archive
export TMP_DIR="/tmp/tmp-fig"
mkdir -p ${TMP_DIR}
chmod 700 ${TMP_DIR}

# Install fig
echo "(*) Installing fig..."

curl -sSL -o ${TMP_DIR}/fig.tar.xz "https://repo.fig.io/generic/${FIG_CHANNEL}/asset/${FIG_VERSION}/${architecture}/fig_headless.tar.xz"
tar -xJf "${TMP_DIR}/fig.tar.xz" -C "${TMP_DIR}" usr
cp -rpv ${TMP_DIR}/usr /

# Clean up
rm -rf /var/lib/apt/lists/*

# Install integrations
if [ -n "$FIG_INTEGRATIONS" ]; then
    echo "(*) Installing integrations..."
    for integration in $(echo $FIG_INTEGRATIONS | sed "s/,/ /g")
    do
        STATUS=$(sudo -u $_REMOTE_USER fig integration install $integration)
        if [[ $? -ne 0 ]]; then
            echo "(!) Failed to install integration: $integration"
            echo "(!) $STATUS"
            exit 1
        else
            echo "(*) Installed integration: $integration"
        fi
    done
fi

echo "Done!"
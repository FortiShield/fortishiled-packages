#!/bin/bash

PACKAGES_REPOSITORY=$1
DEBUG=$2

RESOURCES_PATH="/tmp/unattended_installer"
BUILDER="builder.sh"
INSTALLER="fortishield-install.sh"
SYSTEM_USER="fortishield-user"
HOSTNAME="fortishield-server"

CURRENT_PATH="$( cd $(dirname $0) ; pwd -P )"
ASSETS_PATH="${CURRENT_PATH}/assets"
CUSTOM_PATH="${ASSETS_PATH}/custom"
BUILDER_ARGS="-i"
INSTALL_ARGS="-a"

if [[ "${PACKAGES_REPOSITORY}" == "dev" ]]; then
  BUILDER_ARGS+=" -d"
elif [[ "${PACKAGES_REPOSITORY}" == "staging" ]]; then
  BUILDER_ARGS+=" -d staging"
fi

if [[ "${DEBUG}" = "yes" ]]; then
  INSTALL_ARGS+=" -v"
fi

echo "Using ${PACKAGES_REPOSITORY} packages"

. ${ASSETS_PATH}/steps.sh

# Build install script
bash ${RESOURCES_PATH}/${BUILDER} ${BUILDER_ARGS}
FORTISHIELD_VERSION=$(cat ${RESOURCES_PATH}/${INSTALLER} | grep "fortishield_version=" | cut -d "\"" -f 2)

# System configuration
systemConfig

# Edit installation script
preInstall

# Install
bash ${RESOURCES_PATH}/${INSTALLER} ${INSTALL_ARGS}

systemctl stop fortishield-dashboard filebeat fortishield-indexer fortishield-manager
systemctl enable fortishield-manager
rm -f /var/log/fortishield-indexer/*
rm -f /var/log/filebeat/*

clean

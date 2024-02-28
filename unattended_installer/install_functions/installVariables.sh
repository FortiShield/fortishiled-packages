# Fortishield installer - variables
# Copyright (C) 2015, Fortishield Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

## Package vars
readonly fortishield_major="5.0"
readonly fortishield_version="5.0.0"
readonly filebeat_version="7.10.2"
readonly fortishield_install_vesion="0.1"
readonly source_branch="v${fortishield_version}"

## Links and paths to resources
readonly resources="https://${bucket}/${fortishield_major}"
readonly base_url="https://${bucket}/${repository}"
base_path="$(dirname "$(readlink -f "$0")")"
readonly base_path
config_file="${base_path}/config.yml"
readonly tar_file_name="fortishield-install-files.tar"
tar_file="${base_path}/${tar_file_name}"

readonly filebeat_fortishield_template="https://raw.githubusercontent.com/fortishield/fortishield/${source_branch}/extensions/elasticsearch/7.x/fortishield-template.json"

readonly dashboard_cert_path="/etc/fortishield-dashboard/certs"
readonly filebeat_cert_path="/etc/filebeat/certs"
readonly indexer_cert_path="/etc/fortishield-indexer/certs"

readonly logfile="/var/log/fortishield-install.log"
debug=">> ${logfile} 2>&1"
readonly yum_lockfile="/var/run/yum.pid"
readonly apt_lockfile="/var/lib/dpkg/lock"

## Offline Installation vars
readonly base_dest_folder="fortishield-offline"
readonly manager_deb_base_url="${base_url}/apt/pool/main/w/fortishield-manager"
readonly filebeat_deb_base_url="${base_url}/apt/pool/main/f/filebeat"
readonly filebeat_deb_package="filebeat-oss-${filebeat_version}-amd64.deb"
readonly indexer_deb_base_url="${base_url}/apt/pool/main/w/fortishield-indexer"
readonly dashboard_deb_base_url="${base_url}/apt/pool/main/w/fortishield-dashboard"
readonly manager_rpm_base_url="${base_url}/yum"
readonly filebeat_rpm_base_url="${base_url}/yum"
readonly filebeat_rpm_package="filebeat-oss-${filebeat_version}-x86_64.rpm"
readonly indexer_rpm_base_url="${base_url}/yum"
readonly dashboard_rpm_base_url="${base_url}/yum"
readonly fortishield_gpg_key="https://${bucket}/key/GPG-KEY-FORTISHIELD"
readonly filebeat_config_file="${resources}/tpl/fortishield/filebeat/filebeat.yml"

adminUser="fortishield"
adminPassword="fortishield"

http_port=443
fortishield_aio_ports=( 9200 9300 1514 1515 1516 55000 "${http_port}")
readonly fortishield_indexer_ports=( 9200 9300 )
readonly fortishield_manager_ports=( 1514 1515 1516 55000 )
fortishield_dashboard_port="${http_port}"
wia_yum_dependencies=( systemd grep tar coreutils sed procps-ng gawk lsof curl openssl )
readonly wia_apt_dependencies=( systemd grep tar coreutils sed procps gawk lsof curl openssl )
readonly fortishield_yum_dependencies=( libcap )
readonly fortishield_apt_dependencies=( apt-transport-https libcap2-bin software-properties-common gnupg )
readonly indexer_yum_dependencies=( coreutils )
readonly indexer_apt_dependencies=( debconf adduser procps gnupg apt-transport-https )
readonly dashboard_yum_dependencies=( libcap )
readonly dashboard_apt_dependencies=( debhelper tar curl libcap2-bin gnupg apt-transport-https )
wia_dependencies_installed=()

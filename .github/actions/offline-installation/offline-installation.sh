#!/bin/bash

# Gets the absolute path of the script, used to load the common.sh file
ABSOLUTE_PATH="$( cd $(dirname ${0}) ; pwd -P )"
. ${ABSOLUTE_PATH}/common.sh

check_system
install_dependencies
download_resources

indexer_installation
echo "INFO: Fortishield indexer installation completed."

manager_installation
echo "INFO: Fortishield manager installation completed."

filebeat_installation
echo "INFO: Filebeat installation completed."

dashboard_installation
echo "INFO: Fortishield dashboard installation completed."

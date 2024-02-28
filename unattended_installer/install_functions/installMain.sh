# Fortishield installer - main functions
# Copyright (C) 2015, Fortishield Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

function getHelp() {

    echo -e ""
    echo -e "NAME"
    echo -e "        $(basename "$0") - Install and configure Fortishield central components: Fortishield server, Fortishield indexer, and Fortishield dashboard."
    echo -e ""
    echo -e "SYNOPSIS"
    echo -e "        $(basename "$0") [OPTIONS] -a | -c | -s | -wi <indexer-node-name> | -wd <dashboard-node-name> | -ws <server-node-name>"
    echo -e ""
    echo -e "DESCRIPTION"
    echo -e "        -a,  --all-in-one"
    echo -e "                Install and configure Fortishield server, Fortishield indexer, Fortishield dashboard."
    echo -e ""
    echo -e "        -c,  --config-file <path-to-config-yml>"
    echo -e "                Path to the configuration file used to generate fortishield-install-files.tar file containing the files that will be needed for installation. By default, the Fortishield installation assistant will search for a file named config.yml in the same path as the script."
    echo -e ""
    echo -e "        -dw,  --download-fortishield <deb|rpm>"
    echo -e "                Download all the packages necessary for offline installation. Type of packages to download for offline installation (rpm, deb)"
    echo -e ""
    echo -e "        -fd,  --force-install-dashboard"
    echo -e "                Force Fortishield dashboard installation to continue even when it is not capable of connecting to the Fortishield indexer."
    echo -e ""
    echo -e "        -g,  --generate-config-files"
    echo -e "                Generate fortishield-install-files.tar file containing the files that will be needed for installation from config.yml. In distributed deployments you will need to copy this file to all hosts."
    echo -e ""
    echo -e "        -h,  --help"
    echo -e "                Display this help and exit."
    echo -e ""
    echo -e "        -i,  --ignore-check"
    echo -e "                Ignore the check for system compatibility and minimum hardware requirements."
    echo -e ""
    echo -e "        -o,  --overwrite"
    echo -e "                Overwrites previously installed components. This will erase all the existing configuration and data."
    echo -e ""
    echo -e "        -of,  --offline-installation"
    echo -e "                Perform an offline installation. This option must be used with -a, -ws, -wi, or -wd."
    echo -e ""
    echo -e "        -p,  --port"
    echo -e "                Specifies the Fortishield web user interface port. By default is the 443 TCP port. Recommended ports are: 8443, 8444, 8080, 8888, 9000."
    echo -e ""
    echo -e "        -s,  --start-cluster"
    echo -e "                Initialize Fortishield indexer cluster security settings."
    echo -e ""
    echo -e "        -t,  --tar <path-to-certs-tar>"
    echo -e "                Path to tar file containing certificate files. By default, the Fortishield installation assistant will search for a file named fortishield-install-files.tar in the same path as the script."
    echo -e ""
    echo -e "        -u,  --uninstall"
    echo -e "                Uninstalls all Fortishield components. This will erase all the existing configuration and data."
    echo -e ""
    echo -e "        -v,  --verbose"
    echo -e "                Shows the complete installation output."
    echo -e ""
    echo -e "        -V,  --version"
    echo -e "                Shows the version of the script and Fortishield packages."
    echo -e ""
    echo -e "        -wd,  --fortishield-dashboard <dashboard-node-name>"
    echo -e "                Install and configure Fortishield dashboard, used for distributed deployments."
    echo -e ""
    echo -e "        -wi,  --fortishield-indexer <indexer-node-name>"
    echo -e "                Install and configure Fortishield indexer, used for distributed deployments."
    echo -e ""
    echo -e "        -ws,  --fortishield-server <server-node-name>"
    echo -e "                Install and configure Fortishield manager and Filebeat, used for distributed deployments."
    exit 1

}


function main() {
    umask 177

    if [ -z "${1}" ]; then
        getHelp
    fi

    while [ -n "${1}" ]
    do
        case "${1}" in
            "-a"|"--all-in-one")
                AIO=1
                shift 1
                ;;
            "-c"|"--config-file")
                if [ -z "${2}" ]; then
                    common_logger -e "Error on arguments. Probably missing <path-to-config-yml> after -c|--config-file"
                    getHelp
                    exit 1
                fi
                file_conf=1
                config_file="${2}"
                shift 2
                ;;
            "-fd"|"--force-install-dashboard")
                force=1
                shift 1
                ;;
            "-g"|"--generate-config-files")
                configurations=1
                shift 1
                ;;
            "-h"|"--help")
                getHelp
                ;;
            "-i"|"--ignore-check")
                ignore=1
                shift 1
                ;;
            "-o"|"--overwrite")
                overwrite=1
                shift 1
                ;;
            "-of"|"--offline-installation")
                offline_install=1
                shift 1
                ;;
            "-p"|"--port")
                if [ -z "${2}" ]; then
                    common_logger -e "Error on arguments. Probably missing <port> after -p|--port"
                    getHelp
                    exit 1
                fi
                port_specified=1
                port_number="${2}"
                shift 2
                ;;
            "-s"|"--start-cluster")
                start_indexer_cluster=1
                shift 1
                ;;
            "-t"|"--tar")
                if [ -z "${2}" ]; then
                    common_logger -e "Error on arguments. Probably missing <path-to-certs-tar> after -t|--tar"
                    getHelp
                    exit 1
                fi
                tar_conf=1
                tar_file="${2}"
                shift 2
                ;;
            "-u"|"--uninstall")
                uninstall=1
                shift 1
                ;;
            "-v"|"--verbose")
                debugEnabled=1
                debug="2>&1 | tee -a ${logfile}"
                shift 1
                ;;
            "-V"|"--version")
                showVersion=1
                shift 1
                ;;
            "-wd"|"--fortishield-dashboard")
                if [ -z "${2}" ]; then
                    common_logger -e "Error on arguments. Probably missing <node-name> after -wd|---fortishield-dashboard"
                    getHelp
                    exit 1
                fi
                dashboard=1
                dashname="${2}"
                shift 2
                ;;
            "-wi"|"--fortishield-indexer")
                if [ -z "${2}" ]; then
                    common_logger -e "Arguments contain errors. Probably missing <node-name> after -wi|--fortishield-indexer."
                    getHelp
                    exit 1
                fi
                indexer=1
                indxname="${2}"
                shift 2
                ;;
            "-ws"|"--fortishield-server")
                if [ -z "${2}" ]; then
                    common_logger -e "Error on arguments. Probably missing <node-name> after -ws|--fortishield-server"
                    getHelp
                    exit 1
                fi
                fortishield=1
                winame="${2}"
                shift 2
                ;;
            "-dw"|"--download-fortishield")
                if [ "${2}" != "deb" ] && [ "${2}" != "rpm" ]; then
                    common_logger -e "Error on arguments. Probably missing <deb|rpm> after -dw|--download-fortishield"
                    getHelp
                    exit 1
                fi
                download=1
                package_type="${2}"
                shift 2
                ;;
            *)
                echo "Unknow option: ${1}"
                getHelp
        esac
    done

    cat /dev/null > "${logfile}"

    if [ -z "${download}" ] && [ -z "${showVersion}" ]; then
        common_checkRoot
    fi

    if [ -n "${showVersion}" ]; then
        common_logger "Fortishield version: ${fortishield_version}"
        common_logger "Filebeat version: ${filebeat_version}"
        common_logger "Fortishield installation assistant version: ${fortishield_install_vesion}"
        exit 0
    fi

    common_logger "Starting Fortishield installation assistant. Fortishield version: ${fortishield_version}"
    common_logger "Verbose logging redirected to ${logfile}"

# -------------- Uninstall case  ------------------------------------

    common_checkSystem

    if [ -z "${download}" ]; then
        check_dist
    fi

    if [ -z "${uninstall}" ] && [ -z "${offline_install}" ]; then
        installCommon_installCheckDependencies
    elif [ -n "${offline_install}" ]; then
        offline_checkDependencies
    fi
    
    common_checkInstalled
    checks_arguments
    if [ -n "${uninstall}" ]; then
        installCommon_rollBack
        exit 0
    fi

# -------------- Preliminary checks and Prerequisites --------------------------------

    if [ -z "${configurations}" ] && [ -z "${AIO}" ] && [ -z "${download}" ]; then
        checks_previousCertificate
    fi
    checks_arch
    if [ -n "${ignore}" ]; then
        common_logger -w "Hardware and system checks ignored."
    else
        checks_health
    fi

    if [ -n "${port_specified}" ]; then
        checks_available_port "${port_number}" "${fortishield_aio_ports[@]}"
        dashboard_changePort "${port_number}"
    elif [ -n "${AIO}" ] || [ -n "${dashboard}" ]; then
        dashboard_changePort "${http_port}"
    fi

    if [ -n "${AIO}" ]; then
        rm -f "${tar_file}"
        checks_ports "${fortishield_aio_ports[@]}"
        installCommon_installPrerequisites "AIO"
    fi

    if [ -n "${indexer}" ]; then
        checks_ports "${fortishield_indexer_ports[@]}"
        installCommon_installPrerequisites "indexer"
    fi

    if [ -n "${fortishield}" ]; then
        checks_ports "${fortishield_manager_ports[@]}"
        installCommon_installPrerequisites "fortishield"
    fi

    if [ -n "${dashboard}" ]; then
        checks_ports "${fortishield_dashboard_port}"
        installCommon_installPrerequisites "dashboard"
    fi


# --------------  Fortishield repo  ----------------------

    # Offline installation case: extract the compressed files
    if [ -n "${offline_install}" ]; then
        offline_checkPreinstallation
        offline_extractFiles
    fi

    if [ -n "${AIO}" ] || [ -n "${indexer}" ] || [ -n "${dashboard}" ] || [ -n "${fortishield}" ]; then
        if [ -z "${offline_install}" ]; then
            installCommon_installPrerequisites
        fi
        check_curlVersion
        if [ -z "${offline_install}" ]; then
            installCommon_addFortishieldRepo
        fi
    fi

# -------------- Configuration creation case  -----------------------

    # Creation certificate case: Only AIO and -g option can create certificates.
    if [ -n "${configurations}" ] || [ -n "${AIO}" ]; then
        common_logger "--- Configuration files ---"
        installCommon_createInstallFiles
    fi

    if [ -z "${configurations}" ] && [ -z "${download}" ]; then
        installCommon_extractConfig
        config_file="/tmp/fortishield-install-files/config.yml"
        cert_readConfig
    fi

    # Distributed architecture: node names must be different
    if [[ -z "${AIO}" && -z "${download}" && ( -n "${indexer}"  || -n "${dashboard}" || -n "${fortishield}" ) ]]; then
        checks_names
    fi

    if [ -n "${configurations}" ]; then
        installCommon_removeWIADependencies
    fi

# -------------- Fortishield indexer case -------------------------------

    if [ -n "${indexer}" ]; then
        common_logger "--- Fortishield indexer ---"
        indexer_install
        indexer_configure
        installCommon_startService "fortishield-indexer"
        indexer_initialize
        installCommon_removeWIADependencies
    fi

# -------------- Start Fortishield indexer cluster case  ------------------

    if [ -n "${start_indexer_cluster}" ]; then
        indexer_startCluster
        installCommon_changePasswords
        installCommon_removeWIADependencies
    fi

# -------------- Fortishield dashboard case  ------------------------------

    if [ -n "${dashboard}" ]; then
        common_logger "--- Fortishield dashboard ----"
        dashboard_install
        dashboard_configure
        installCommon_startService "fortishield-dashboard"
        installCommon_changePasswords
        dashboard_initialize
        installCommon_removeWIADependencies

    fi

# -------------- Fortishield server case  ---------------------------------------

    if [ -n "${fortishield}" ]; then
        common_logger "--- Fortishield server ---"
        manager_install
        manager_configure
        if [ -n "${server_node_types[*]}" ]; then
            manager_startCluster
        fi
        installCommon_startService "fortishield-manager"
        filebeat_install
        filebeat_configure
        installCommon_changePasswords
        installCommon_startService "filebeat"
        installCommon_removeWIADependencies
    fi

# -------------- AIO case  ------------------------------------------

    if [ -n "${AIO}" ]; then

        common_logger "--- Fortishield indexer ---"
        indexer_install
        indexer_configure
        installCommon_startService "fortishield-indexer"
        indexer_initialize
        common_logger "--- Fortishield server ---"
        manager_install
        manager_configure
        installCommon_startService "fortishield-manager"
        filebeat_install
        filebeat_configure
        installCommon_startService "filebeat"
        common_logger "--- Fortishield dashboard ---"
        dashboard_install
        dashboard_configure
        installCommon_startService "fortishield-dashboard"
        installCommon_changePasswords
        dashboard_initializeAIO
        installCommon_removeWIADependencies

    fi

# -------------- Offline case  ------------------------------------------

    if [ -n "${download}" ]; then
        common_logger "--- Download Packages ---"
        offline_download
    fi


# -------------------------------------------------------------------

    if [ -z "${configurations}" ] && [ -z "${download}" ] && [ -z "${offline_install}" ]; then
        installCommon_restoreFortishieldrepo
    fi

    if [ -n "${AIO}" ] || [ -n "${indexer}" ] || [ -n "${dashboard}" ] || [ -n "${fortishield}" ]; then
        eval "rm -rf /tmp/fortishield-install-files ${debug}"
        common_logger "Installation finished."
    elif [ -n "${start_indexer_cluster}" ]; then
        common_logger "Fortishield indexer cluster started."
    fi

}

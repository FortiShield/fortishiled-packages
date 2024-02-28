# Certificate tool - Main functions
# Copyright (C) 2015, Fortishield Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

function getHelp() {

    echo -e ""
    echo -e "NAME"
    echo -e "        fortishield-cert-tool.sh - Manages the creation of certificates of the Fortishield components."
    echo -e ""
    echo -e "SYNOPSIS"
    echo -e "        fortishield-cert-tool.sh [OPTIONS]"
    echo -e ""
    echo -e "DESCRIPTION"
    echo -e "        -a,  --admin-certificates </path/to/root-ca.pem> </path/to/root-ca.key>"
    echo -e "                Creates the admin certificates, add root-ca.pem and root-ca.key."
    echo -e ""
    echo -e "        -A, --all </path/to/root-ca.pem> </path/to/root-ca.key>"
    echo -e "                Creates certificates specified in config.yml and admin certificates. Add a root-ca.pem and root-ca.key or leave it empty so a new one will be created."
    echo -e ""
    echo -e "        -ca, --root-ca-certificates"
    echo -e "                Creates the root-ca certificates."
    echo -e ""
    echo -e "        -v,  --verbose"
    echo -e "                Enables verbose mode."
    echo -e ""
    echo -e "        -wd,  --fortishield-dashboard-certificates </path/to/root-ca.pem> </path/to/root-ca.key>"
    echo -e "                Creates the Fortishield dashboard certificates, add root-ca.pem and root-ca.key."
    echo -e ""
    echo -e "        -wi,  --fortishield-indexer-certificates </path/to/root-ca.pem> </path/to/root-ca.key>"
    echo -e "                Creates the Fortishield indexer certificates, add root-ca.pem and root-ca.key."
    echo -e ""
    echo -e "        -ws,  --fortishield-server-certificates </path/to/root-ca.pem> </path/to/root-ca.key>"
    echo -e "                Creates the Fortishield server certificates, add root-ca.pem and root-ca.key."
    echo -e ""
    echo -e "        -tmp,  --cert_tmp_path </path/to/tmp_dir>"
    echo -e "                Modifies the default tmp directory (/tmp/fortishield-ceritificates) to the specified one."
    echo -e "                Must be used along with one of these options: -a, -A, -ca, -wi, -wd, -ws"
    echo -e ""

    exit 1

}

function main() {

    umask 177

    cert_checkOpenSSL

    if [ -n "${1}" ]; then
        while [ -n "${1}" ]
        do
            case "${1}" in
            "-a"|"--admin-certificates")
                if [[ -z "${2}" || -z "${3}" ]]; then
                    common_logger -e "Error on arguments. Probably missing </path/to/root-ca.pem> </path/to/root-ca.key> after -a|--admin-certificates"
                    getHelp
                    exit 1
                else
                    cadmin=1
                    rootca="${2}"
                    rootcakey="${3}"
                    shift 3
                fi
                ;;
            "-A"|"--all")
                if  [[ -n "${2}" && "${2}" != "-v" && "${2}" != "-tmp" ]]; then
                    # Validate that the user has entered the 2 files
                    if [[ -z ${3} ]]; then
                        if [[ ${2} == *".key" ]]; then
                            common_logger -e "You have not entered a root-ca.pem"
                            exit 1
                        else
                            common_logger -e "You have not entered a root-ca.key" 
                            exit 1
                        fi
                    fi
                    all=1
                    rootca="${2}"
                    rootcakey="${3}"
                    shift 3
                else
                    all=1
                    shift 1
                fi
                ;;
            "-ca"|"--root-ca-certificate")
                ca=1
                shift 1
                ;;
            "-h"|"--help")
                getHelp
                ;;
            "-v"|"--verbose")
                debugEnabled=1
                shift 1
                ;;
            "-wd"|"--fortishield-dashboard-certificates")
                if [[ -z "${2}" || -z "${3}" ]]; then
                    common_logger -e "Error on arguments. Probably missing </path/to/root-ca.pem> </path/to/root-ca.key> after -wd|--fortishield-dashboard-certificates"
                    getHelp
                    exit 1
                else
                    cdashboard=1
                    rootca="${2}"
                    rootcakey="${3}"
                    shift 3
                fi
                ;;
            "-wi"|"--fortishield-indexer-certificates")
                if [[ -z "${2}" || -z "${3}" ]]; then
                    common_logger -e "Error on arguments. Probably missing </path/to/root-ca.pem> </path/to/root-ca.key> after -wi|--fortishield-indexer-certificates"
                    getHelp
                    exit 1
                else
                    cindexer=1
                    rootca="${2}"
                    rootcakey="${3}"
                    shift 3
                fi
                ;;
            "-ws"|"--fortishield-server-certificates")
                if [[ -z "${2}" || -z "${3}" ]]; then
                    common_logger -e "Error on arguments. Probably missing </path/to/root-ca.pem> </path/to/root-ca.key> after -ws|--fortishield-server-certificates"
                    getHelp
                    exit 1
                else
                    cserver=1
                    rootca="${2}"
                    rootcakey="${3}"
                    shift 3
                fi
                ;;
            "-tmp"|"--cert_tmp_path")
                if [[ -n "${3}" || ( "${cadmin}" == 1 || "${all}" == 1 || "${ca}" == 1 || "${cdashboard}" == 1 || "${cindexer}" == 1 || "${cserver}" == 1 ) ]]; then
                    if [[ -z "${2}" || ! "${2}" == /* ]]; then
                        common_logger -e "Error on arguments. Probably missing </path/to/tmp_dir> or path does not start with '/'."
                        getHelp
                        exit 1
                    else
                        cert_tmp_path="${2}"
                        shift 2
                    fi
                else
                    common_logger -e "Error: -tmp must be used along with one of these options: -a, -A, -ca, -wi, -wd, -ws"
                    getHelp
                    exit 1
                fi
                ;;
            *)
                echo "Unknow option: ${1}"
                getHelp
            esac
        done

        if [[ -d "${base_path}"/fortishield-certificates ]]; then
            if [ -n "$(ls -A "${base_path}"/fortishield-certificates)" ]; then
                common_logger -e "Directory fortishield-certificates already exists in the same path as the script. Please, remove the certs directory to create new certificates."
                exit 1
            fi
        fi
        
        if [[ ! -d "${cert_tmp_path}" ]]; then
            mkdir -p "${cert_tmp_path}"
            chmod 744 "${cert_tmp_path}"
        fi

        cert_readConfig

        if [ -n "${debugEnabled}" ]; then
            debug="2>&1 | tee -a ${logfile}"
        fi

        if [[ -n "${cadmin}" ]]; then
            cert_checkRootCA
            cert_generateAdmincertificate
            common_logger "Admin certificates created."
            cert_cleanFiles
            cert_setpermisions
            eval "mv ${cert_tmp_path} ${base_path}/fortishield-certificates ${debug}"
        fi

        if [[ -n "${all}" ]]; then
            cert_checkRootCA
            cert_generateAdmincertificate
            common_logger "Admin certificates created."
            if cert_generateIndexercertificates; then
                common_logger "Fortishield indexer certificates created."
            fi
            if cert_generateFilebeatcertificates; then
                common_logger "Fortishield Filebeat certificates created."
            fi
            if cert_generateDashboardcertificates; then
                common_logger "Fortishield dashboard certificates created."
            fi
            cert_cleanFiles
            cert_setpermisions
            eval "mv ${cert_tmp_path} ${base_path}/fortishield-certificates ${debug}"
        fi

        if [[ -n "${ca}" ]]; then
            cert_generateRootCAcertificate
            common_logger "Authority certificates created."
            cert_cleanFiles
            eval "mv ${cert_tmp_path} ${base_path}/fortishield-certificates ${debug}"
        fi

        if [[ -n "${cindexer}" ]]; then
            if [ ${#indexer_node_names[@]} -gt 0 ]; then
                cert_checkRootCA
                cert_generateIndexercertificates
                common_logger "Fortishield indexer certificates created."
                cert_cleanFiles
                cert_setpermisions
                eval "mv ${cert_tmp_path} ${base_path}/fortishield-certificates ${debug}"
            else
                common_logger -e "Indexer node not present in config.yml."
                exit 1
            fi
        fi

        if [[ -n "${cserver}" ]]; then
            if [ ${#server_node_names[@]} -gt 0 ]; then
                cert_checkRootCA
                cert_generateFilebeatcertificates
                common_logger "Fortishield Filebeat certificates created."
                cert_cleanFiles
                cert_setpermisions
                eval "mv ${cert_tmp_path} ${base_path}/fortishield-certificates ${debug}"
            else
                common_logger -e "Server node not present in config.yml."
                exit 1
            fi
        fi

        if [[ -n "${cdashboard}" ]]; then
            if [ ${#dashboard_node_names[@]} -gt 0 ]; then
                cert_checkRootCA
                cert_generateDashboardcertificates
                common_logger "Fortishield dashboard certificates created."
                cert_cleanFiles
                cert_setpermisions
                eval "mv ${cert_tmp_path} ${base_path}/fortishield-certificates ${debug}"
            else
                common_logger -e "Dashboard node not present in config.yml."
                exit 1
            fi
        fi

    else
        getHelp
    fi

}
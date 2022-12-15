#!/bin/sh
# Created by Wazuh, Inc. <info@wazuh.com>.
# Copyright (C) 2018 Wazuh Inc.
# This program is a free software; you can redistribute
# it and/or modify it under the terms of GPLv2
# Wazuh HP-UX Package builder.


install_path="/var/ossec"
current_path=`pwd`
source_directory=${current_path}/wazuh-sources
configuration_file="${source_directory}/etc/preloaded-vars.conf"
PATH=$PATH:/usr/local/bin
target_dir="${current_path}/output"
checksum_dir=""
wazuh_version=""
wazuh_revision="1"
depot_path=""
control_binary=""

build_environment() {

    # Resizing partitions for Site Ox boxes (used by Wazuh team)
    if grep 'siteox.com' /etc/motd > /dev/null 2>&1; then
        for partition in "/home" "/tmp"; do
            partition_size=$(df -b | grep $partition | awk -F' ' '{print $5}')
            if [[ ${partition_size} -lt "3145728" ]]; then
                echo "Resizing $partition partition to 3GB"
                volume=$(cat /etc/fstab | grep $partition | awk -F' ' '{print $1}')
                lvextend -L 3000 $volume
                fsadm -b 3072000 $partition > /dev/null 2>&1
          fi
      done
    fi

    echo "Installing dependencies."
    depot=""
    if [ -z "${depot_path}" ]
    then
        depot=$current_path/depothelper-2.20-ia64_64-11.31.depot
    else
        depot=$depot_path
    fi

    if [ -n "${ftp_ip}" ] && [ -n "${ftp_port}" ] && [ -n "${ftp_user}" ] && [ -n "${ftp_pass}" ]
    then
        fpt_connection="-b 64 -p ${ftp_ip}:${ftp_port}:${ftp_user}:${ftp_pass}"
    fi

    echo "fpt_connection: $fpt_connection"

    #Install dependencies
    swinstall -s $depot \*
    /usr/local/bin/depothelper $fpt_connection -f curl
    /usr/local/bin/depothelper $fpt_connection -f unzip
    /usr/local/bin/depothelper $fpt_connection -f gcc
    /usr/local/bin/depothelper $fpt_connection -f make
    /usr/local/bin/depothelper $fpt_connection -f bash
    /usr/local/bin/depothelper $fpt_connection -f gzip
    /usr/local/bin/depothelper $fpt_connection -f automake
    /usr/local/bin/depothelper $fpt_connection -f autoconf
    /usr/local/bin/depothelper $fpt_connection -f libtool
    /usr/local/bin/depothelper $fpt_connection -f coreutils
    /usr/local/bin/depothelper $fpt_connection -f gdb
    /usr/local/bin/depothelper $fpt_connection -f perl
    /usr/local/bin/depothelper $fpt_connection -f regex
}

config() {
    echo USER_LANGUAGE="en" > ${configuration_file}
    echo USER_NO_STOP="y" >> ${configuration_file}
    echo USER_INSTALL_TYPE="agent" >> ${configuration_file}
    echo USER_DIR=${install_path} >> ${configuration_file}
    echo USER_DELETE_DIR="y" >> ${configuration_file}
    echo USER_CLEANINSTALL="y" >> ${configuration_file}
    echo USER_BINARYINSTALL="y" >> ${configuration_file}
    echo USER_AGENT_SERVER_IP="MANAGER_IP" >> ${configuration_file}
    echo USER_ENABLE_SYSCHECK="y" >> ${configuration_file}
    echo USER_ENABLE_ROOTCHECK="y" >> ${configuration_file}
    echo USER_ENABLE_OPENSCAP="y" >> ${configuration_file}
    echo USER_ENABLE_ACTIVE_RESPONSE="y" >> ${configuration_file}
    echo USER_CA_STORE="n" >> ${configuration_file}
}

compute_version_revision() {
    wazuh_version=$(cat ${source_directory}/src/VERSION | cut -d "-" -f1 | cut -c 2-)

    echo ${wazuh_version} > /tmp/VERSION
    echo ${wazuh_revision} > /tmp/REVISION

    return 0
}

download_source() {
    echo " Downloading source"
    /usr/local/bin/curl -k -L -O https://github.com/wazuh/wazuh/archive/${wazuh_branch}.zip
    /usr/local/bin/unzip ${wazuh_branch}.zip
    mv wazuh-* ${source_directory}
    compute_version_revision
}

check_version() {
    wazuh_version=`cat ${source_directory}/src/VERSION`
    number_version=`echo "${wazuh_version}" | cut -d v -f 2`
    major=`echo $number_version | cut -d . -f 1`
    minor=`echo $number_version | cut -d . -f 2`
    deps_version=`cat ${source_directory}/src/Makefile | grep "DEPS_VERSION =" | cut -d " " -f 3`
}

compile() {
    echo "Compiling code"
    # Compile and install wazuh
    cd ${source_directory}/src
    config
    check_version
    gmake deps RESOURCES_URL=http://packages.wazuh.com/deps/${deps_version} TARGET=agent
    gmake TARGET=agent USE_SELINUX=no
    bash ${source_directory}/install.sh
    cd $current_path
}

create_package() {
    echo "Creating package"

    if [ ! -d ${target_dir} ]; then
        mkdir -p ${target_dir}
    fi

    #Build package
    VERSION=`cat /tmp/VERSION`
    rm ${install_path}/wodles/oscap/content/*.xml
    wazuh_version=`echo "${wazuh_version}" | cut -d v -f 2`
    pkg_name="wazuh-agent-${wazuh_version}-${wazuh_revision}-hpux-11v3-ia64.tar"
    tar cvpf ${target_dir}/${pkg_name} ${install_path} /sbin/init.d/wazuh-agent /sbin/rc2.d/S97wazuh-agent /sbin/rc3.d/S97wazuh-agent

    if [ "${compute_checksums}" = "yes" ]; then
        cd ${target_dir}
        pkg_checksum="$(openssl dgst -sha512 ${pkg_name} | cut -d' ' -f "2")"
        echo "${pkg_checksum}  ${pkg_name}" > ${checksum_dir}/${pkg_name}.sha512
    fi
}

set_control_binary() {
    if [ -e ${source_directory}/src/VERSION ]; then
        wazuh_version=`cat ${source_directory}/src/VERSION`
        number_version=`echo "${wazuh_version}" | cut -d v -f 2`
        major=`echo $number_version | cut -d . -f 1`
        minor=`echo $number_version | cut -d . -f 2`

        if [ "$major" -le "4" ] && [ "$minor" -le "1" ]; then
            control_binary="ossec-control"
        else
            control_binary="wazuh-control"
        fi
    fi
}

# Uninstall agent.

clean() {
    exit_code=$1
    set_control_binary

    if [ ! -z $control_binary ]; then
        ${install_path}/bin/${control_binary} stop
    fi

    rm -rf ${install_path}

    find /sbin -name "*wazuh-agent*" -exec rm {} \;
    userdel wazuh
    groupdel wazuh

    exit ${exit_code}
}

show_help() {
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "    -e Install all the packages necessaries to build the TAR package"
    echo "    -b <branch> Select Git branch. Example v3.5.0"
    echo "    -s <tar_directory> Directory to store the resulting tar package. By default, an output folder will be created."
    echo "    -p <tar_home> Installation path for the package. By default: /var"
    echo "    -c, --checksum Compute the SHA512 checksum of the TAR package."
    echo "    -d <path_to_depot>, --depot Change the path to depothelper package (by default current path)."
    echo "    -h Shows this help"
    echo
    exit $1
}

build_package() {
    download_source
    compile
    create_package
    clean 0
}

# Main function, processes user input
main() {
    # If the script is called without arguments
    # show the help
    if [[ -z $1 ]] ; then
        show_help 0
    fi

    build_env="no"
    build_pkg="no"

    while [ -n "$1" ]
    do
        case $1 in
            "-b")
                if [ -n "$2" ]
                    then
                    wazuh_branch="$2"
                    build_pkg="yes"
                    shift 2
                else
                    show_help 1
                fi
            ;;
            "-h")
                show_help
                exit 0
            ;;
            "-e")
                build_env="yes"
                shift 1
            ;;
            "--ftp_port")
                if [ -n "$2" ]
                    then
                    ftp_port="$2"
                    shift 2
                else
                    show_help 1
                fi
            ;;
            "--ftp_ip")
                if [ -n "$2" ]
                    then
                    ftp_ip="$2"
                    shift 2
                else
                    show_help 1
                fi
            ;;
            "--ftp_user")
                if [ -n "$2" ]
                    then
                    ftp_user="$2"
                    shift 2
                else
                    show_help 1
                fi
            ;;
            "--ftp_pass")
                if [ -n "$2" ]
                    then
                    ftp_pass="$2"
                    shift 2
                else
                    show_help 1
                fi
            ;;
            "-p")
                if [ -n "$2" ]
                    then
                    install_path="$2"
                    shift 2
                else
                    show_help 1
                fi
            ;;
            "-s")
                if [ -n "$2" ]
                    then
                    target_dir="$2"
                    shift 2
                else
                    show_help 1
                fi
            ;;
            "-c" | "--checksum")
                if [ -n "$2" ]; then
                    checksum_dir="$2"
                    compute_checksums="yes"
                    shift 2
                else
                    compute_checksums="yes"
                    shift 1
                fi
            ;;
            "-d")
                if [ -n "$2" ]
                    then
                    depot_path="$2"
                    shift 2
                else
                    show_help 1
                fi
            ;;
            *)
                show_help 1
        esac
    done

    if [[ "${build_env}" = "yes" ]]; then
        build_environment || exit 1
        exit 0
    fi

    if [ -z "${checksum_dir}" ]; then
        checksum_dir="${target_dir}"
    fi

    if [[ "${build_pkg}" = "yes" ]]; then
        build_package || clean 1
    fi

    return 0
}

main "$@"
